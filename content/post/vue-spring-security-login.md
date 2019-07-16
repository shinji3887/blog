---
title: "使用vue集成spring security进行安全登陆"
date: 2019-05-17
excerpt: "在前后端分离的状态下，传统的spring security认证模式也需要做一点改造，以适应ajax的前端访问模式"
description: "在前后端分离的状态下，传统的spring security认证模式也需要做一点改造，以适应ajax的前端访问模式"
gitalk: true
image: "https://lupeier.cn-sh2.ufileos.com/hand-keyboard-secured-34203.jpg"
author: L'
tags:
    - Spring Cloud
    - vue
categories: [ Tech ]
---

> 在前后端分离的状态下，传统的spring security认证模式也需要做一点改造，以适应ajax的前端访问模式

现在前后端分离的开发模式已经成为主流，好处不多说了，说说碰到的问题和坑。首先要解决的肯定是跨域问题，这个问题之前已经有讨论，请移步[这里查看](https://www.jianshu.com/p/8f5e7b547dfc)。另外一个问题是传统的spring security安全机制是基于页面跳转的，使用302重定向（认证成功跳转至之前访问的页面，认证失败或未认证跳转至系统设置的默认登陆页面）。传统应用这么弄没问题，但现在vue一般都是基于axios进行ajax访问，ajax请求是没法直接处理302跳转的（浏览器会直接处理跳转请求，ajax的callback拿到的是跳转后的返回页面，在spring security中就是登陆首页，不符合需求）。幸好spring security所有的流程都是可以自定义的，我们可以扩展一下各个环节的流程。spring boot版本为2.1.4.RELEASE，对应的spring security版本为5.1.5.RELEASE

### 核心配置类

`WebSecurityConfig`类配置如下

```java
import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationDetailsSource;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationFailureHandler;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.security.web.authentication.WebAuthenticationDetails;
import org.springframework.security.web.authentication.logout.SimpleUrlLogoutSuccessHandler;

import com.bocsh.mer.security.MyUserDetailsService;

@Configuration
@EnableWebSecurity
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {
	
	@Autowired
	MyUserDetailsService myDetailService;
	
	@Autowired
    private AuthenticationDetailsSource<HttpServletRequest, WebAuthenticationDetails> authenticationDetailsSource;
	
	protected Log log = LogFactory.getLog(this.getClass());
	
	@Autowired
    private AuthenticationProvider authenticationProvider; 

	@Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
		
        auth.authenticationProvider(authenticationProvider);
    }
	
	//定义登陆成功返回信息
	private class AjaxAuthSuccessHandler extends SimpleUrlAuthenticationSuccessHandler {
	    @Override
	    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response, Authentication authentication) throws IOException, ServletException {
	    	
	    	//User user = (User)SecurityContextHolder.getContext().getAuthentication().getPrincipal();
	    	log.info("商户[" + SecurityContextHolder.getContext().getAuthentication().getPrincipal() +"]登陆成功！");
	    	//登陆成功后移除session中验证码信息
	    	request.getSession().removeAttribute("codeValue");
	    	request.getSession().removeAttribute("codeTime");
	    	
	    	response.setContentType("application/json;charset=utf-8");
            PrintWriter out = response.getWriter();
            out.write("{\"status\":\"ok\",\"msg\":\"登录成功\"}");
            out.flush();
            out.close();
	    }
	}
	
	//定义登陆失败返回信息
	private class AjaxAuthFailHandler extends SimpleUrlAuthenticationFailureHandler {
	    @Override
	    public void onAuthenticationFailure(HttpServletRequest request, HttpServletResponse response, AuthenticationException exception) throws IOException, ServletException {
	    	//登陆失败后移除session中验证码信息
	    	request.getSession().removeAttribute("codeValue");
	    	request.getSession().removeAttribute("codeTime");
	    	
	    	response.setContentType("application/json;charset=utf-8");
	    	response.setStatus(HttpStatus.UNAUTHORIZED.value());
            PrintWriter out = response.getWriter();
            out.write("{\"status\":\"error\",\"msg\":\"请检查用户名、密码或验证码是否正确\"}");
            out.flush();
            out.close();
	    }
	}
	
	//定义异常返回信息
	public class UnauthorizedEntryPoint implements AuthenticationEntryPoint {
	    @Override
	    public void commence(HttpServletRequest request, HttpServletResponse response, AuthenticationException authException) throws IOException, ServletException {
	    	response.sendError(HttpStatus.UNAUTHORIZED.value(),authException.getMessage());
        }

	}
	
	//定义登出成功返回信息
	private class AjaxLogoutSuccessHandler extends SimpleUrlLogoutSuccessHandler  {

		public void onLogoutSuccess(HttpServletRequest request, HttpServletResponse response,
				Authentication authentication) throws IOException, ServletException {
			response.setContentType("application/json;charset=utf-8");
            PrintWriter out = response.getWriter();
            out.write("{\"status\":\"ok\",\"msg\":\"登出成功\"}");
            out.flush();
            out.close();
		}
	}
	
	@Override
    protected void configure(HttpSecurity http) throws Exception {
		http
		.exceptionHandling().authenticationEntryPoint(new UnauthorizedEntryPoint())
		.and()
		.csrf().disable()
		.authorizeRequests()                   
            .antMatchers("/users/login_page","/users/captcha").permitAll()
            .anyRequest().authenticated()
            .and().formLogin().loginPage("/users/login_page")
                              .successHandler(new AjaxAuthSuccessHandler())
                              .failureHandler(new AjaxAuthFailHandler())
                              .loginProcessingUrl("/login")
                              .authenticationDetailsSource(authenticationDetailsSource)
            .and()
            .logout().logoutSuccessHandler(new AjaxLogoutSuccessHandler())
            .logoutUrl("/logout");
    }
}
```

这里分别说明：`configure`方法配置整体的认证规则，即除了`/users/login_page`和`/users/captcha`这两个方式之外全部需要认证，同时在`formLogin`方法中设置了两个自定义的handler分别处理认证成功、认证失败的情况，这里我们设置直接返回json字符串，content-type设置为`application/json;charset=utf-8`，这样在认证完毕之后就不用自动302跳转了，而是交由axios框架来进行处理。

`UnauthorizedEntryPoint`定义了异常处理的逻辑，同理我们也是直接返回ajax信息而不做跳转。

### axios相关配置

```js
instance.interceptors.response.use(res => {
      let { data } = res
      this.destroy(url)
      if (this.shade) {
        Spin.hide()
        Modal.success({
          title: '操作成功'
        })
      }
      console.log(res)
      return data
    }, error => {
      console.log(error)
      var code = error.response.status
      if (code === 401) {
        Cookies.remove(TOKEN_KEY)
        window.location.href = '/login'
        Message.error('未登录，或登录失效，请登录')
      }
```

这里面我们定义了一个响应拦截器，在error情况下，判断若返回码为401（就是我们在spring security中自定义的handler的错误状态码），则自动跳转至登陆页面。这样实现了在会话失效的情况下，点击前端任意需要访问后端api的按钮，均会触发跳转登录首页的效果，符合我们的预期。实际情况中一般前端框架都会自己带一套基于cookies的认证机制，这里我们把cookies的失效时间可以设置的长一点（一般可以设为一天），以保障还是以后端会话的失效时间为准。

### 验证码处理

一般我们在处理用户登录，为安全考虑需要加入图形验证码。这里需要注意的一点是**验证码也必须作为login这个action的处理参数传入**，否则的话这个验证码只是做了前端页面验证，实际在处理login事件的时候是没有验证码的，这样就没有意义了。而spring security框架默认只能帮助我们处理用户名+密码的这样验证方式，这样就需要对认证方式进行扩展。

#### WebAuthenticationDetails

```java
import javax.servlet.http.HttpServletRequest;

import org.springframework.security.web.authentication.WebAuthenticationDetails;

public class MyWebAuthenticationDetails extends WebAuthenticationDetails {
    /**
     * 
     */
    private static final long serialVersionUID = 6975601077710753878L;
    
    private String username;
    
    private String password;
    
    private String validcode;
    
    private String sessionCodeValue;
    
    private long sessionCodeTime;
    
    public String getSessionCodeValue() {
		return sessionCodeValue;
	}

	public void setSessionCodeValue(String sessionCodeValue) {
		this.sessionCodeValue = sessionCodeValue;
	}

    public long getSessionCodeTime() {
		return sessionCodeTime;
	}

	public void setSessionCodeTime(long sessionCodeTime) {
		this.sessionCodeTime = sessionCodeTime;
	}

	public String getUsername() {
		return username;
	}

	public void setUsername(String username) {
		this.username = username;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public String getValidcode() {
		return validcode;
	}

	public void setValidcode(String validcode) {
		this.validcode = validcode;
	}

	public MyWebAuthenticationDetails(HttpServletRequest request) {
        super(request);
        username = request.getParameter("username");
        password = request.getParameter("password");
        validcode = request.getParameter("validateCode");
        sessionCodeValue = (String)request.getSession().getAttribute("codeValue");
        sessionCodeTime = (Long)request.getSession().getAttribute("codeTime");
    }
}
```

这边前三个参数是从页面的login请求中传过来的，后面两个参数是在页面上请求生成图片验证码的时候我们设置到session里面去，以便于后续的验证

#### AuthenticationDetailsSource

```java
import javax.servlet.http.HttpServletRequest;

import org.springframework.security.authentication.AuthenticationDetailsSource;
import org.springframework.security.web.authentication.WebAuthenticationDetails;
import org.springframework.stereotype.Component;

@Component
public class MyAuthenticationDetailsSource implements AuthenticationDetailsSource<HttpServletRequest, WebAuthenticationDetails> {

    @Override
    public WebAuthenticationDetails buildDetails(HttpServletRequest context) {
        return new MyWebAuthenticationDetails(context);
    }
}
```

这个类实现了一个自定义的接口，返回我们刚才定义的`MyWebAuthenticationDetails`资源

#### AuthenticationProvider

```java
import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import com.bocsh.mer.service.MerchantService;

@Component
public class MyAuthenticationProvider implements AuthenticationProvider {
    
	protected Log log = LogFactory.getLog(this.getClass());
	
	@Autowired
	MerchantService ms;
	
    @Override
    public Authentication authenticate(Authentication authentication) 
            throws AuthenticationException {
    	log.info("now start custom authenticate process!");
        MyWebAuthenticationDetails details = (MyWebAuthenticationDetails) authentication.getDetails();  
        
        //校验码判断
        if(!details.getValidcode().equals(details.getSessionCodeValue())) {
        	log.info("validate code error");
        	throw new BadCredentialsException("authenticate fail！");
        }

        //校验码有效期
        if((new Date()).getTime() - details.getSessionCodeTime() > 60000) {
        	log.info("validate code expired!");
        	throw new BadCredentialsException("authenticate fail！");
        }
        
        //验密
        String inpass="";
		try {
			inpass = ms.getPass(details.getUsername());
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
        if(!inpass.equals(details.getPassword())) {
        	log.info("password error");
        	throw new BadCredentialsException("authenticate fail！");
        }
        	
        
        Collection<GrantedAuthority> auths=new ArrayList<GrantedAuthority>(); 
        auths.add(new SimpleGrantedAuthority("ROLE_ADMIN"));
        return new UsernamePasswordAuthenticationToken(details.getUsername(),details.getPassword(),auths);
   
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return authentication.equals(UsernamePasswordAuthenticationToken.class);
    }

}
```

这里自定义了一个`AuthenticationProvider `来处理实际的认证业务逻辑，在这里可以方便的根据我们需要来进行自定义，我这边分别做了验证码校验、效期校验和验密，大家可以根据需要定制。认证成功就返回一个`UsernamePasswordAuthenticationToken`对象并配置好合适的权限（权限基于标准的RBAC模型，我这里为了讲解方便设置为ROLE_ADMIN，这里不展开讲了）。如果认证失败，只需要抛出一个异常（AuthenticationException的子类），这样spring security会自动找到失败页面进行返回，对应我们上面定义的`AjaxAuthFailHandler`这个类。

package org.molgenis.framework.server;

import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.molgenis.framework.db.Database;
import org.molgenis.framework.security.Login;

public class FrontControllerAuthenticator
{
	
	public enum LoginStatus {
		SUCCESSFULLY_LOGGED_IN, ALREADY_LOGGED_IN, AUTHENTICATION_FAILURE, EXCEPTION_THROWN
	}
	
	public enum LogoutStatus {
		SUCCESSFULLY_LOGGED_OUT, ALREADY_LOGGED_OUT, EXCEPTION_THROWN
	}

	
	public static LoginStatus login(MolgenisRequest request, String username,
			String password)
	{
		System.out.println("FrontControllerAuthenticator LOGIN called");
		try
		{
			
			Database db = request.getDatabase();
			
			if(db.getSecurity().isAuthenticated())
			{
				return LoginStatus.ALREADY_LOGGED_IN;
			}
			
			// try to login
			boolean loggedIn = db.getSecurity().login(db, username, password);
			
			System.out.println("FrontControllerAuthenticator loggedIn: " + loggedIn);

			if (loggedIn)
			{
				//TODO: Missing redirect???
				//Login login = new org.molgenis.auth.DatabaseLogin(request.getDatabase(), "ClusterDemo");

				// store login in session
				request.getRequest().getSession().setAttribute("login", db.getSecurity());
				return LoginStatus.SUCCESSFULLY_LOGGED_IN;
			}
			else
			{
				return LoginStatus.AUTHENTICATION_FAILURE;
			}
		}
		catch (Exception e)
		{
			e.printStackTrace();
			return LoginStatus.EXCEPTION_THROWN;
		}
	}

	public static LogoutStatus logout(MolgenisRequest request, MolgenisResponse response)
	{
		System.out.println("FrontControllerAuthenticator LOGOUT called");
		try
		{
			
			Database db = request.getDatabase();
			
			if(!db.getSecurity().isAuthenticated())
			{
				return LogoutStatus.ALREADY_LOGGED_OUT;
			}
			
			//logout from database
			//FIXME: needed??
			request.getDatabase().getSecurity().logout(request.getDatabase());
			
			//invalidate the session
			//FIXME correct??
			response.getResponse().setHeader("WWW-Authenticate",
					"BASIC realm=\"MOLGENIS\"");
			response.getResponse().sendError(
					HttpServletResponse.SC_UNAUTHORIZED);
			request.getRequest().getSession().invalidate();
			
			return LogoutStatus.SUCCESSFULLY_LOGGED_OUT;
		}
		catch (Exception e)
		{
			e.printStackTrace();
			return LogoutStatus.EXCEPTION_THROWN;
		}
		

//		// remove login fron session
//		HttpSession session = request.getRequest().getSession();
//		session.setAttribute("login", null);
//
//		// get current db login and invalidate the session
//		// if user is not logged in, and login is required
//		Login userLogin = null;
//		userLogin = request.getDatabase().getSecurity();
//		
//		if ((!userLogin.isAuthenticated() && userLogin.isLoginRequired()))
//		{
//			response.getResponse().setHeader("WWW-Authenticate",
//					"BASIC realm=\"MOLGENIS\"");
//			response.getResponse().sendError(
//					HttpServletResponse.SC_UNAUTHORIZED);
//			session.invalidate();
//			return;
//		}
//
//		// logout from db
//		userLogin.logout(request.getDatabase());
	}

}

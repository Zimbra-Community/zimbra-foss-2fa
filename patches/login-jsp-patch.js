/*Start Zeta Alliance Zimbra FOSS 2FA patch*/

/* On your Zimbra server your need to put this code in the login screen.
 * open /opt/zimbra/jetty/webapps/zimbra/public/login.jsp
 * And add it before the final < / script > tag.
 * */

function zetaCheckEnter(e){
   e = e || event;
   var txtArea = /textarea/i.test((e.target || e.srcElement).tagName);
   if(txtArea || (e.keyCode || e.which || e.charCode || 0) == 13)
   {
      //if enter pressed, we try to login
      zetaDoLogin();
   }   
   return txtArea || (e.keyCode || e.which || e.charCode || 0) !== 13;
}

function zetaDoLogin(){

   //to=do: add a request here to the back-end and see if this user needs to enter OTP
   var needsOTP = true;
   if(needsOTP)
   {
      if(!document.getElementById("zeta-otp"))
      {
         //Add OTP input field
         var originalLoginForm = document.getElementsByName("loginForm");
         originalLoginForm[0].style.display='none';
         originalLoginForm[0].insertAdjacentHTML('beforebegin', 
            '<table class="form" id="totpTable" style="height:140px;width:350px;">' + 
            '<tbody>' + 
            '<tr>' + 
            '<td><label for="zeta-otp"><fmt:message key="twoFactorAuthCodeLabel"/>:</label></td>' + 
            '<td><input id="zeta-otp" class="zLoginField" name="zeta-otp" type="text" value="" size="40" maxlength="1024" style="margin-right:20px" autocomplete="off" onkeypress="zetaCheckEnter(event);"></td>' + 
            '<td class="submitTD">' +
            '<button type="button" onclick="zetaDoLogin()" id="zetaSubmit" class="ZLoginButton DwtButton"><fmt:message key='twoFactorAuthVerifyCode'/></button></td>' + 
            '</tr>' + 
            '</tbody>' + 
            '</table>'
         );
         document.getElementById('zeta-otp').focus();
      }
      else
      {
         //Submit the form with the OTP value
         document.getElementById('password').value = document.getElementById('password').value + document.getElementById('zeta-otp').value;
         zetaPerformLogin();
      }
   }
   else
   {
      zetaPerformLogin();
   }   
}

function zetaPerformLogin() {
   //Perform regular login
   var originalSubmitButton=document.querySelectorAll('input[type=submit]');
   originalSubmitButton[0].click();
}      

document.querySelector('form').onkeypress = zetaCheckEnter;
var originalSubmitButton=document.querySelectorAll('input[type=submit]');
originalSubmitButton[0].style.display='none';

originalSubmitButton[0].insertAdjacentHTML('afterend', '<button type="button" onclick="zetaDoLogin()" id="zetaSubmit" class="ZLoginButton DwtButton">'+originalSubmitButton[0].value+'</Button>');

/*End Zeta Alliance Zimbra FOSS 2FA patch*/

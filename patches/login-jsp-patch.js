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
   //Submit the form with the OTP value 
   document.getElementById('password').value = document.getElementById('password').value + document.getElementById('zeta-otp').value;
   document.getElementById('zeta-otp').value = '';
   var originalSubmitButton=document.querySelectorAll('input[type=submit]');
   originalSubmitButton[0].click();
}      

document.querySelector('form').onkeypress = zetaCheckEnter;
var originalSubmitButton=document.querySelectorAll('input[type=submit]');
originalSubmitButton[0].style.display='none';

document.getElementById('password').parentElement.parentElement.insertAdjacentHTML('afterend', 
   '<tr>' + 
   '<td><label for="zeta-otp">2FA:</label></td>' + 
   '<td><input id="zeta-otp" class="zLoginField" type="text" value="" size="40" maxlength="1024" autocomplete="off" onkeypress="zetaCheckEnter(event);" placeholder="Leave blank if you have no 2FA."></td>' + 
   '</tr>'
);

originalSubmitButton[0].insertAdjacentHTML('beforebegin', '<button type="button" onclick="zetaDoLogin()" id="zetaSubmit" class="ZLoginButton DwtButton">'+originalSubmitButton[0].value+'</Button>');

/*End Zeta Alliance Zimbra FOSS 2FA patch*/

# Zimbra Open Source Two Factor Authentication with PrivacyIDEA


If you find Zimbra WebDAV Client useful and want to support its continued development, you can make donations via:
- PayPal: info@barrydegraaff.tk
- Bank transfer: IBAN NL55ABNA0623226413 ; BIC ABNANL2A

[![2FA demo](https://img.youtube.com/vi/MHRaFS7K_B8/0.jpg)](https://www.youtube.com/watch?v=MHRaFS7K_B8) 

Demo: https://www.youtube.com/watch?v=MHRaFS7K_B8

You can use the software in this repository to set-up your Zimbra Open Source Edition server with Two Factor Authentication. The 2FA parts are powered by PrivacyIDEA and will run in a Docker container on your Zimbra server.

Technically this makes Zimbra support all 2FA tokens PrivacyIDEA supports. This includes TOTP, HOTP, and Yubikey. 

This project uses an LDAP Proxy provided by PrivacyIDEA. So the usernames and passwords are read by PrivacyIDEA from the Zimbra LDAP (or ActiveDirectory if you want). And the 2FA tokens are read from PrivacyIDEA database. The user can log in using 2FA by typing the username, password and token. Or just with username/password if the user has no token yet.


The installation takes around 1GB of space.

### Installing
If you have a single server Zimbra running on CentOS or Ubuntu AND you want to use Zimbra's internal LDAP to store usernames and password you can use the automated installer. Tested on CentOS 7 and Ubuntu 18.04.5 LTS.

    wget https://raw.githubusercontent.com/Zimbra-Community/zimbra-foss-2fa/master/2fa-installer.sh -O /tmp/2fa-installer.sh
    chmod +rx /tmp/2fa-installer.sh
    /tmp/2fa-installer.sh

If you have a multi-server Zimbra installation, or want to use Active Directory as back-end for your usernames/passwords. Or if you want to know all configuration steps, follow the manual install guide.

https://github.com/Zimbra-Community/zimbra-foss-2fa/blob/master/README-MANUAL-INSTALL.md


### License

Copyright (C) 2015-2021  Barry de Graaff [Zeta Alliance](https://zetalliance.org/)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.

   



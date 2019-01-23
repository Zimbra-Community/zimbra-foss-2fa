import sys
sys.stdout = sys.stderr
from privacyidea.app import create_app
application = create_app(config_name="production", config_file="/etc/privacyidea/pi.cfg")

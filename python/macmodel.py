
import urllib2
from xml.etree import ElementTree


def model_code_from_serial(serial):
    if "serial" in serial.lower():
        return None
    if len(serial) in (11, 12):
        return serial[8:].decode("ascii")
    return None
    

def lookup_mac_model_code(model_code):
    try:
        f = urllib2.urlopen("http://support-sp.apple.com/sp/product?cc=%s&lang=en_US" % model_code, timeout=2)
        et = ElementTree.parse(f)
        return et.findtext("configCode").decode("utf-8")
    except:
        return None
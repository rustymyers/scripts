#!/usr/bin/python


import sys
import optparse
from xml.etree import ElementTree


def flatten_pkg_path(path):
    path = path.rpartition("/")[2]
    return "#" + path
    

def flatten_pkg_refs(dist):
    packages = dict()
    
    for pkgref in dist.findall("choice/pkg-ref"):
        pkg_id = pkgref.get("id")
        pkg_auth = pkgref.get("auth")
        pkg_path = pkgref.text
        packages[pkg_id] = {
            "auth": "Root" if pkg_auth == "root" else pkg_auth,
            "pkg": flatten_pkg_path(pkg_path)
        }
        del pkgref.attrib["auth"]
        del pkgref.text
    
    for pkgref in dist.findall("pkg-ref"):
        pkg_id = pkgref.get("id")
        pkgref.set("auth", packages[pkg_id]["auth"])
        pkgref.text = packages[pkg_id]["pkg"]
    
    return dist
    

def main(argv):
    p = optparse.OptionParser()
    p.set_usage("""Usage: %prog [options]""")
    p.add_option("-v", "--verbose", action="store_true",
                 help="Verbose output.")
    options, argv = p.parse_args(argv)
    if len(argv) != 2:
        print >>sys.stderr, p.get_usage()
        return 1
    
    dist_path = argv[1]
    
    with open(dist_path) as f:
        dist = ElementTree.parse(f)
    
    flatten_pkg_refs(dist)
    
    with open(dist_path, "w") as f:
        dist.write(f, encoding="utf-8")
    
    return 0
    

if __name__ == '__main__':
    sys.exit(main(sys.argv))
    

var fs = require('fs');
var path = require('path');


var configXml = fs.readFileSync("config.xml", 'utf8');
configXml = configXml.toLowerCase();
var reg = /<name>(.+)<\/name>/gi;

var result;
if ((result = reg.exec(configXml)) != null) {
    var packageName = result[1];
    console.log("With the package name: " + packageName);
    var path = "platforms/ios/" + packageName + "/Bridging-Header.h";
    
    if (fs.existsSync(path)) {
        var data = fs.readFileSync(path, 'utf8');
        var result = data + "\r\n#import <ZXingObjC/ZXingObjC.h>";
        fs.writeFileSync(path, result, 'utf8');
    } else {
        console.error("Can not find Bridging-Header.h at path: " + path);
    }
}else{
    console.error("config.xml name node error ");
}

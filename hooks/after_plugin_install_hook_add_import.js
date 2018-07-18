var fs = require('fs');
var path = require('path');

var packageobj = JSON.parse(fs.readFileSync("package.json", 'utf8'));
var packageName = packageobj.name;
var path = `platforms/ios/${packageName}/Bridging-Header.h`;

if (fs.existsSync(path)) {
    console.log("With the package name: " + packageName);
    var data = fs.readFileSync(path, 'utf8');
    var result = data + "\r\n#import <ZXingObjC/ZXingObjC.h>";
    fs.writeFileSync(path, result, 'utf8');
} else {
    console.error(`Can not find Bridging-Header.h at path: ${path}`);
}
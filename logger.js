var util = require('util');

// Member variables
var loggerName = '-';

function doLog(type, args, error) {
  var stacktrace = new Error().stack;
  var callerLine = stacktrace.split("\n")[3];
  callerLine = callerLine.substr(callerLine.indexOf("at ") + 3, callerLine.length);
  var methodName = callerLine.split(" ")[0];
  var lineNumber = callerLine.split(":")[1];

  var newArgs = [];
  newArgs.push("[%s][%s][pid:%s][%s] %s():%d ");
  newArgs.push(new Date().toISOString());
  newArgs.push(type);
  newArgs.push(process.pid);
  newArgs.push(loggerName);
  newArgs.push(methodName);
  newArgs.push(lineNumber);

  if (args.length > 0) {
    newArgs[0] = newArgs[0] + args[0];
    for (var i=1; i<args.length; i++) {
      newArgs.push(args[i]);
    }
  }

  var message = util.format.apply(util, newArgs);
  console.log(message);
}

exports.debug = function() {
  doLog("DEBUG", arguments, false);
}

exports.info = function() {
  doLog("INFO", arguments, false);
}

exports.warn = function() {
  doLog("WARN", arguments, true);
}

exports.error = function() {
  doLog("ERROR", arguments, true);
}

exports.logger = function(name) {
  loggerName = name;
  return exports;
}

var util = require("util");
var events = require("events");

var parameters = [];
var options = [];
var args = [];

module.exports = new events.EventEmitter();

module.exports.options = function() {
    return options;
}

module.exports.arguments = function() {
    return args;
}

module.exports.getOptions = function() {
    if (arguments.length == 1) {
        var definitions = arguments[0];
        for (var def in definitions) {
            addParam(def, definitions[def]);
        }
    } else {
        for (var i=0; i<arguments.length; i++) {
            addParam(arguments[i], undefined);
        }
    }

    return module.exports.parse(process.argv);
}

module.exports.parse = function(argv) {
    options = [];
    args = [];

    var i = 2;
    while (i < argv.length) {
        var original = arg = argv[i];

        if (arg === '--') {
            // end of options marker
            i++;
            break;
        } else if (arg.charAt(0) == '-') {
            // Remove the first - (or --)
            arg = arg.substring(1);
            if (arg.charAt(0) == '-')
                arg = arg.substring(1);
        } else {
            break;
        }

        var param = getParam(arg);
        if (!param) {
            error('Unknown option: ' + original);
        }

        var name = param.name;
        if (param.type) {
            if (i + 1 < argv.length) {
                var value = argv[i + 1];
                // TODO : only multiple values when specified
                if (options[name] === undefined) {
                    options[name] = value;
                } else if (Array.isArray(options[name])) {
                    options[name].push(value);
                } else {
                    var values = [options[name], value];
                }
                i++;
            } else {
                error('Option ' + original + ' requires an argument');
            }
        } else {
            if (param.negated) {
                options[param.negated] = false;
            } else {
                options[name] = true;
            }
        }

        i++;
    }

    while (i < argv.length) {
        var arg = argv[i];
        args.push(arg);
        i++;
    }

    // Add default values when required
    for (var name in parameters) {
        if (options[name] && parameters[name].value) {
            options[name] = parameters[name].value;
        }
    }

    return options;
}

module.exports.usage = function(message, verbose) {
    if (message) {
        console.error(message);
    }

    // TODO : this should use the value passed to parse
    var script = process.argv[1];
    script = script.substring(script.lastIndexOf('/') + 1);

    // TODO : use a buffer
    var usage = "    node " + script;

    var maxWidth = 80;
    var width = usage.length;
    var indent = usage.length;

    for (var name in parameters) {
        var param = parameters[name];

        var def = " [";

        // Primary name
        if (name.length == 1) {
            def += "-" + name;
        } else {
            def += "--" + name;
        }

        // Aliases
        for (var i=0; i<param.aliases.length; i++) {
            def += "|";
            if (param.aliases[i].length == 1) {
                def += "-" + param.aliases[i];
            } else {
                def += "--" + param.aliases[i];
            }
        }

        // Argument
        if (param.type === 's') {
            def += " string";
        } else if (param.type === 'i') {
            def += " int";
        } else if (param.type === 'f') {
            def += " float";
        } else if (param.type) {
            def += " argument";
        }

        def += "]";

        if (width + def.length > maxWidth) {
            usage += "\n";
            width = 0;
            for (var i=0; i<indent; i++) {
                usage += " ";
                width++;
            }
        }

        usage += def;
        width += def.length;
    }

    usage = "Usage:\n" + usage;

    console.log(usage);
}

function addParam(def, value) {
    var negated = false;

    if (def.charAt(def.length - 1) == '!') {
        negated = true;
        def = def.substring(0, def.length - 1);
    }

    var parts = def.split('=');
    var aliases = parts[0].split('|');
    var name = aliases.shift();

    var type = undefined;
    if (parts.length == 2) {
        if (negated) {
            error('Negated options may not have arguments');
        }
        type = parts[1];
    }

    parameters[name] = {
        name: name,
        aliases: aliases,
        type: type,
        value: value,
    };

    // Add the negated versions of the options
    if (negated) {
        addNegatedParam(name, name);
        for (var i=0; i<aliases.length; i++) {
            addNegatedParam(aliases[i], name);
        }
    }
}

function addNegatedParam(name, negatedParam) {
    if (name.length > 1) {
        parameters['no-' + name] = {
            name: 'no-' + name,
            aliases: ['no' + name],
            negated: negatedParam,
        };
    }
}

function getParam(alias) {
    if (parameters[alias]) {
        return parameters[alias];
    }

    for (var name in parameters) {
        var aliases = parameters[name].aliases;
        for (var i=0; i<aliases.length; i++) {
            if (aliases[i] == alias) {
                return parameters[name];
            }
        }
    }

    return null;
}

function error(message) {
    module.exports.emit('error', new Error(message));
}

var logger = require("./logger.js"),
    util   = require("util"),
    events = require("events"),
    spawn  = require("child_process").spawn;

var endsWithNewLine = new RegExp("\n$");

function SQLite(databaseFile) {
    this.file = databaseFile;
}

util.inherits(SQLite, events.EventEmitter);

SQLite.prototype.extractAndEmit = function(buffer) {
    var lines = buffer.split("\n")
    for (var i=0; i<lines.length; i++) {
        var record = new String(lines[i]).split("\|");
        this.emit("data", record);
    }
}

SQLite.prototype.fetch = function(sql, callback) {
    logger.debug("Fetching: ", sql);

    var this_ = this;
    var buffer = ""; // TODO : use Buffer

    var process = spawn("sqlite3", [this.file, sql]);

    process.stdout.on("data", function (data) {
        logger.debug("Received data:--- start ---\n%s--- end ---\n", data);
        buffer += data;
        // TODO : this does not work if the data contains a "\n"
        if (endsWithNewLine.test(data)) {
            this_.extractAndEmit(buffer);
            buffer = "";
        }
    });

    process.stderr.on("data", function (data) {
        logger.error("Error: " + data);
        this_.emit("error", data);
    });

    process.on("exit", function (code) {
        logger.debug("Process exited with code " + code);
        if (code != 0) {
            this_.emit("error", "Process exited with code " + code);
        }
        if (buffer) {
            this_.extractAndEmit(buffer);
            buffer = "";
        }
        this_.emit("end");
    });
}

exports.open = function(file) {
    if (!file) throw new Error("Database file path is required");
    return new SQLite(file);
}

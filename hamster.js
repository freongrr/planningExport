var logger = require("./logger.js"),
    sqlite = require("./sqlite.js");

var dbFile;

// TODO : best way to set up the object?
exports.withFile = function(file) {
    dbFile = file;
    return this;
}

exports.tasks = function (fromDate, toDate, callback) {
    var sql =
        "SELECT strftime('%Y-%m-%d', f.start_time) AS date,\n" +
        "       strftime('%H:%M', f.start_time) AS start,\n" +
        "       strftime('%s', f.end_time) - strftime('%s', f.start_time),\n" +
        "       a.name,\n" +
        "       c.name,\n" +
        "       f.id,\n" +
        "       replace(f.description, x'0A', ' ')\n" +
        "  FROM facts f\n" +
        "       INNER JOIN activities a ON a.id = f.activity_id\n" +
        "       LEFT JOIN categories c ON c.id=a.category_id\n" +
        " WHERE f.end_time IS NOT NULL\n";
    if (fromDate)
        sql += " AND start_time >= '" + fromDate + " 00:00'";
    if (toDate)
        sql += " AND start_time <=  '" + toDate + " 23:59'";
    sql += "ORDER BY f.end_time, f.id\n";

    var tasks = [];

    var db = sqlite.open(dbFile);
    db.on("error", function(error) {
        console.log("ERROR: " + error);
    });

    db.on("data", function (record) {
        tasks.push(convert(record));
    });

    db.on("end", function () {
        // Callback or event
        callback(tasks);
    });

    db.fetch(sql);
};

function convert(record) {
    logger.debug("Converting record: ", record);

    // TODO : why am I doing that?
    var activity = record[3];
    if (activity) {
        activity = activity.replace("^[\s\-]+(\w)", "\1");
        activity = activity.replace("(\w)[\s\-]+$", "\1");
    }

    // Remove the final dot
    var description = record[6];
    if (description) {
        description = description.replace("([^\.])\.$", "\1", "g");
    }

    var task = {
        id: record[5],
        date: record[0],
        start: record[1],
        time: record[2] / 3600.00,
        name: activity,
        category: record[4],
        description: description
    };

    logger.debug(" >> ", task);

    return task;
}

# grafana-ctrl-docker

Docker image with help tool for run common setup operations for _Grafana_.

Operations like upload dashboards, datasources, ... from json file or loaded from
option in command line.

As docker image the base is curl image with shell-script entrypoint that "wraps"
operations/actions to grafana

# Configuration and run.

All main configuration values should be provided by environment variables to
docker. This is a description of them:

* `GRAFANA_ENDPOINT`: Protocol, host and port of grafana. Default value `http://grafana:3000`

* `GRAFANA_AUTH_BEARER`: Token used to authenticate to grafana.
  See [Grafana API auth docs](http://docs.grafana.org/http_api/auth/) for more info.

  Use of this configuration has preference over `GRAFANA_AUTH_USERPASSWD`

* `GRAFANA_AUTH_USERPASSWD`: User and password to connect with grafana. This
  will works only if grafana has enable basic auth. Default value `admin:admin`

  This variable has not effect if `GRAFANA_AUTH_BEARER` is defined.

* `GRAFANA_WAIT_TIMEOUT`: If defined must get a integer with number of seconds
  up to wait for _Grafana_ (TCP check)

* `CURL_OPTIONS`: Common options to use with curl. By default ${CURL_OPTIONS}

* `PATH_FIND_PATTERN`: _egrep pattern_ to apply filter when find for files with
  `--path` and similar options: Default value `.*\.json`

# Command allowed

This docker support a lits of commands to run perations over grafana. This is a
basic description. For more info run docker with `--help` option:

* `import-dashboards OPTIONS`: Import one or more dashboards to _Grafana_.
  Valid `OPTIONS` are:
    `--json JSON_BODY`: Use value of `JSON_BODY` as payload of _dashboard_
      specification.

    `--file JSON_FILE`: Similar to `--json` option but load payload from
      `JSON_FILE`

    `--path PATH`. similar to --file but search for all files in a path that
      match with `$PATH_FIND_PATTERN` _egrep pattern_.

    You can set any of these options multiple times to import more than one
    dashboard in one-shoot.

* `new-datasources OPTIONS`: Create one or more new _Data Sources_ in _Grafana_.
  Valid `OPTIONS` are:
    `--json JSON_BODY`: Use value of `JSON_BODY` as payload of _datasource_
      specification.

    `--file JSON_FILE`: Similar to `--json` option but load payload from
      `JSON_FILE`

    `--path PATH`. similar to `--file` but search for all files in a path that
      match with `$PATH_FIND_PATTERN` _egrep pattern_.

    You can set any of these options multiple times to create more than one
    datasource in one-shoot.

* `new-users OPTIONS`: create one or more new users.
  Valid `OPTIONS` are:
    `--json JSON_BODY`: Use value of `JSON_BODY` as payload of user
      specification with id USER_ID.

    `--file JSON_FILE`: Similar to `--json` option but load payload from
      `JSON_FILE`.

    `--path PATH`. similar to `--file` but search for all files in a path that
      match with `$PATH_FIND_PATTERN` _egrep pattern_

    You can set any of these options multiple times to create more than one
    user in one-shoot.

# JSON expected formats #

Before describe allowed _JSON_ formats is important to note that values of
**environment variables** can be replaced _on-fly_ **in files**.

Any string with `{{ENV_VAR_NAME}}` found in any json file will be replaced by
value of `ENV_VAR_NAME` **only** if `ENV_VAR_NAME` is defined.

## New user

This is an example of a valid JSON to create new user:

```json
{
  "name": "k",
  "email": "k@t.com",
  "login": "k",
  "password": "kpassword"
}
```

You can find more examples in [user tests path](test/users)


## New data source

This is an example of a valid JSON to create new data source:

```json
{
  "name": "Prometheus",
  "type": "prometheus",
  "access": "proxy",
  "url": "http://prometheus:9090",
  "password": "",
  "user": "",
  "database": "",
  "basicAuth": false,
  "isDefault": false,
  "jsonData": {}
}
```

You can find more examples in [datasource tests path](test/datasources)

If you are trying to get datasoruce data from other _Grafana_ instance, one
approach is use `/api/datasources` API to get the info. See
[Data Source HTTP API](http://docs.grafana.org/v4.6/http_api/data_source/) for
more information.

## Import Dashboard

This is an example of a valid JSON to import a dashboard:

```json
{
  "dashboard": {
    "annotations": {
      "list": [
        {
          "builtIn": 1,
          "datasource": "-- Grafana --",
          "enable": true,
          "hide": true,
          "iconColor": "rgba(0, 211, 255, 1)",
          "name": "Annotations & Alerts",
          "type": "dashboard"
        }
      ]
    },
    "editable": true,
    "gnetId": null,
    "graphTooltip": 0,
    "hideControls": false,
    "id": null,
    "links": [],
    "rows": [
      {
        "collapse": false,
        "height": "250px",
        "panels": [
          {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "Elastic Search",
            "fill": 1,
            "id": 1,
            "legend": {
              "avg": false,
              "current": false,
              "max": false,
              "min": false,
              "show": true,
              "total": false,
              "values": false
            },
            "lines": true,
            "linewidth": 1,
            "links": [],
            "nullPointMode": "null",
            "percentage": false,
            "pointradius": 5,
            "points": false,
            "renderer": "flot",
            "seriesOverrides": [],
            "spaceLength": 10,
            "span": 12,
            "stack": false,
            "steppedLine": false,
            "targets": [
              {
                "bucketAggs": [
                  {
                    "field": "time",
                    "id": "2",
                    "settings": {
                      "interval": "auto",
                      "min_doc_count": 0,
                      "trimEdges": 0
                    },
                    "type": "date_histogram"
                  }
                ],
                "dsType": "elasticsearch",
                "metrics": [
                  {
                    "field": "select field",
                    "id": "1",
                    "type": "count"
                  }
                ],
                "refId": "A",
                "timeField": "time"
              }
            ],
            "thresholds": [],
            "timeFrom": null,
            "timeShift": null,
            "title": "Documents in logs-* (Elastic Search)",
            "tooltip": {
              "shared": true,
              "sort": 0,
              "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
              "buckets": null,
              "mode": "time",
              "name": null,
              "show": true,
              "values": []
            },
            "yaxes": [
              {
                "format": "short",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": null,
                "show": true
              },
              {
                "format": "short",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": null,
                "show": true
              }
            ]
          }
        ],
        "repeat": null,
        "repeatIteration": null,
        "repeatRowId": null,
        "showTitle": false,
        "title": "Dashboard Row",
        "titleSize": "h6"
      }
    ],
    "schemaVersion": 14,
    "style": "dark",
    "tags": [],
    "templating": {
      "list": []
    },
    "time": {
      "from": "now-6h",
      "to": "now"
    },
    "timepicker": {
      "refresh_intervals": [
        "5s",
        "10s",
        "30s",
        "1m",
        "5m",
        "15m",
        "30m",
        "1h",
        "2h",
        "1d"
      ],
      "time_options": [
        "5m",
        "15m",
        "1h",
        "6h",
        "12h",
        "24h",
        "2d",
        "7d",
        "30d"
      ]
    },
    "timezone": "",
    "title": "ElasticSearch Dashboard",
    "version": 1
  },
  "overwrite": true,
  "inputs": []
}
```

You can find more examples in [dashboards tests path](test/dashboards)

If you are trying to get _dashboard_ data from other _Grafana_ instance, better approach is export data using GUI: Go to dashboard you are getting for export, Click on Share, Export, View Json.

Copy all json displayed in frame to your favourite editor. This data as is can not be directly imported by `grafana-ctrl` tool. You need to wrap
JSON with next structure:

```json
{
  "dashboard": <<<YOUR DATA COPIED HERE>>>,
  "overwrite": true,
  "inputs": []
}
```

This new payload is _fully compatible_ with `grafna-ctrl` tool.

As last steep look for `dashboard.id` key in your new wrapped data and change existing value (for example `12`) with `null`.

For example if we try to export following _click path_ previously described, we can see something similar to:

```json
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "hideControls": false,
  "id": 10,
  "links": [],
  "rows": [
    {
      "collapse": false,
      "height": "250px",
      "panels": [
        {
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "Elastic Search",
          "fill": 1,
          "id": 1,
          "legend": {
            "avg": false,
            "current": false,
            "max": false,
            "min": false,
            "show": true,
            "total": false,
            "values": false
          },
          "lines": true,
          "linewidth": 1,
          "links": [],
          "nullPointMode": "null",
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "seriesOverrides": [],
          "spaceLength": 10,
          "span": 12,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "bucketAggs": [
                {
                  "field": "time",
                  "id": "2",
                  "settings": {
                    "interval": "auto",
                    "min_doc_count": 0,
                    "trimEdges": 0
                  },
                  "type": "date_histogram"
                }
              ],
              "dsType": "elasticsearch",
              "metrics": [
                {
                  "field": "select field",
                  "id": "1",
                  "type": "count"
                }
              ],
              "refId": "A",
              "timeField": "time"
            }
          ],
          "thresholds": [],
          "timeFrom": null,
          "timeShift": null,
          "title": "Documents in logs-* (Elastic Search)",
          "tooltip": {
            "shared": true,
            "sort": 0,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            },
            {
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            }
          ]
        }
      ],
      "repeat": null,
      "repeatIteration": null,
      "repeatRowId": null,
      "showTitle": false,
      "title": "Dashboard Row",
      "titleSize": "h6"
    }
  ],
  "schemaVersion": 14,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "",
  "title": "ElasticSearch Dashboard",
  "version": 1
}
```

And when we follow describe steps (wrap JSON with `dahsboard`, and adding
`inputs` and `"overwrite": true` fields) and change `"id": 10,` (line `19` in
snippet) to '"id": null', we have valid payload (example at begin of current
section)


# Running with docker-compose

Current project contains a simple `docker-compose.yml` to run and check tool
with _Grafana_.

Execute next command to start-up a _Docker compose_ environment with _Grafana_
and some items added:

```bash
docker-compose up --build grafana-ctl
```

Now you can browse to [Grafana exposed in localhost](htpp://localhost:3000),
authenticate with default user (`admin`/`admin`) and see users, data sources and
dashboards created by `grafana-ctrl` tool

To destroy environment run next command:

```bash
docker-compose down --rmi local -v --remove-orphans
```

See [Docker compose page](https://docs.docker.com/compose/) for more information.

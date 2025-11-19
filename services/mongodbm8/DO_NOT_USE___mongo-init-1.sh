#!/bin/bash
# mongo <<EOF
# var config = {
#     "_id": "dbrs",
#     "version": 1,
#     "members": [
#         {
#             "_id": 1,
#             "host": "host.docker.internal:27017",
#             "priority": 3
#         },
#         {
#             "_id": 2,
#             "host": "host.docker.internal:27018",
#             "priority": 2
#         },
#         {
#             "_id": 3,
#             "host": "host.docker.internal:27019",
#             "priority": 1
#         }
#     ]
# };
mongosh <<EOF
var config = {
    "_id": "rs0",
    "version": 1,
    "members": [
        {
            "_id": 0,
            "host": "mongodb-1:27017",
            "priority": 3
        },
        {
            "_id": 1,
            "host": "mongodb-2:27018",
            "priority": 2
        },
        {
            "_id": 2,
            "host": "mongodb-3:27019",
            "priority": 1
        }
    ]
};
rs.initiate(config, { force: true });
rs.status();
EOF
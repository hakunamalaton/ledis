# Ledis

Stripped down version of Redis named Ledis (for light-weight Redis).
Link to deployment Ledis CLI: https://lediscli.herokuapp.com

## Table of contents
* [Introduction](#Introduction)
* [Functional Requirements](#functional-requirements)
* [Set up](#set-up)

# Introduction
Redis is a popular in-memory data structure store that is widely used in many applications, either as cache, complex data structure, or store application data itself.

In this project, I will build a simple stripped down version of Redis named Ledis (for light-weight Redis).

Scope of project:
* Data structures: String, Set
* Special features: Expire, snapshots
* A simple web CLI (similar to redis-cli)

# Functional Requirements
This simple Ledis will contains some of commands like: String commands, Set commands, Data Expiration commands, Snapshot commands and Error Handling. It also includes a CLI for using.

## String commands
Strings are the most basic kind of Ledis value that you can set a simple key-value in Ledis. Some commands of String commands:

* SET key value: set a string value, always overwriting what is saved under key
* GET key: get a string value at key

## Set commands
Set is a unordered collection of unique string values (duplicates not allowed). Some commands of Set commands:

* SADD key value1 [value2...]: add values to set stored at key
* SREM key value1 [value2...]: remove values from set
* SMEMBERS key: return array of all members of set
* SINTER [key1] [key2] [key3] ...: set intersection among all set stored in specified keys. Return array of members of the result set

## Data Expiration
Some actions are available in Ledis for listing all keys, deleting a key, set a time to live for a key and get the timeout of the key. These commands below are data expiration in Ledis:

* KEYS: List all available keys
* DEL key: delete a key
* EXPIRE key seconds: set a timeout on a key, seconds is a positive integer (by default a key has no expiration). Return the number of seconds if the timeout is set
* TTL key: query the timeout of a key

## Snapshot
Benefits of snapshot in Ledis is to save or back-up data. Some actions will be available in Ledis:

* SAVE: save current state in a snapshot
* RESTORE: restore from the last snapshot,

## Error Handling
When an error happens, a structural of error statement will be returned: "Error" together with the cause of error if possible. Some errors you can get: 

* Unknown command: when you try to input an unavailable command
* Number of arguments: when you input an command with lack or excess of arguments
* Syntax error: likely the Unknown command but it uses for redundant arguments in SET commands
* Wrong kind of value: when you try to override a string key by a set key
* Not an integer or out of range: when the third argument in EXPIRE commands is not integer

# Set up
Just go to the URL: https://lediscli.herokuapp.com and get started!

Autofs Puppet Module
====================

####Table of Contents
1. [Description](#description)
2. [Requirements](#requirements)
3. [Setup](#setup)
  * [Installation](#install)
  * [How to Use this Module](#using)
  * [Troubleshooting](#troubleshooting)
4. [Contact](#contact)

Description
-----------
The Autofs module is a Puppet module for managing the configuration of automount
network file system. This is a global module designed to be used by any
organization. This module assumes the use of Hiera to set variables and serve up
configuration files.

Requirements
------------
* OS: Debian Linux or Enterprise Linux (and their variants):
  * autofs is not built for Windows or Mac so they are not supported.
  * This module does NOT support Solaris Autofs.
* Hieradata YAML Backend

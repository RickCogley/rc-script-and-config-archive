#!/bin/sh
# --
# otrs.queuemaker.sh - a queue and group making script for OTRS.
# Copyright (c) Rick Cogley <rick@esolia.co.jp>, eSolia Inc.
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Get the GNU General Public License from the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# --

echo "otrs.queuemaker.sh - <\$Revision: 0.1 $>"

# parse user input
while getopts "b:c:" Option
do
  case $Option in
    b)
      # otrs bin loc
      OTRS_BIN=$OPTARG
    ;;
    c)
      # company name
      COMP_NAME=$OPTARG
    ;;
  esac
done

shift $(($OPTIND - 1))

if [ "x${OTRS_BIN}" == "x" ] || [ "x${COMP_NAME}" == "x" ]; then
    echo ""
    echo "Usage: otrs.queuemaker.sh -b path/bin -c COMPANYINITIALS "
    echo ""
    echo "  Try: otrs.queuemaker.sh -b /opt/otrs/bin -c SOMECOINC"
    echo ""
    exit 1
fi

#  make group and queues
`${OTRS_BIN}/otrs.addGroup -n ${COMP_NAME}`
`${OTRS_BIN}/otrs.addQueue -g ${COMP_NAME} ${COMP_NAME}`
`${OTRS_BIN}/otrs.addQueue -g ${COMP_NAME} ${COMP_NAME}::Support`
`${OTRS_BIN}/otrs.addQueue -g ${COMP_NAME} ${COMP_NAME}::Projects`
`${OTRS_BIN}/otrs.addQueue -g ${COMP_NAME} ${COMP_NAME}::Memo`
`${OTRS_BIN}/otrs.addQueue -g ${COMP_NAME} ${COMP_NAME}::Sales`

exit 0

#!/bin/bash
###############################################################################
# Shell script for getting results of all the verify queries in Dabble Protrac

echo ====== ESOLIA TIME AND EXPENSE VERIFICATION TESTS ====== > esolia-protrac-verify.txt
echo The results for many of these tests are expected to be blank, if data is correct. >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Time Sheets Not Open Or Approved >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/a6bbf176-57a7-4bb9-a9a4-31a9533abf42/verify-timesheetsnotopenorapproved.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Time Sheets Not Ready for Review >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/9b7798b4-0c80-4e52-b61e-8df7c6deeaaf/verify-timesheetsnotreadyforreview.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Time Sheets Ready For Review But Still Open >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/5e16d667-53c6-48cb-8a85-5afb09052898/verify-timesheetsreadyforreviewbutstillopen.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Times With No Professional >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/8c9bfb90-5785-4c72-92be-0020448782d5/verify-timeswithnoprofessional.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Expense Sheets Not Open Or Approved >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/d0428b06-ceec-4c38-8d04-d49a9430523a/verify-expensesheetsnotopenorapproved.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Expense Sheets Not Ready For Review >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/c8584958-e6de-4e7b-a62a-b07584829c98/verify-expensesheetsnotreadyforreview.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Expense Sheets Ready For Review But Still Open >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/1653b554-6b22-4ff3-82ac-f638683cf682/verify-expensesheetsreadyforreviewbutstillopen.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Expenses With No Professional >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/a9e2fc57-2daa-4cc0-ae74-a3f525a7b1f0/verify-expenseswithnoprofessional.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Internal Times With Empty Total Hours >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/ab06d92e-48f0-44cc-99f3-299799220264/verify-internaltimeswithemptytotalhours.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Internal Times With Invalid Internal Hours >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/c8d9f6d2-adcb-4bf6-98f4-e5da37989420/verify-internaltimeswithinvalidinternalhours.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Internal Times With Non-billable Hrs >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/8685569d-e982-480a-819d-92c0586ccfdc/verify-internaltimeswithnon-billablehrs.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Leave Entries With Internal Hours >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/71b9cb8c-e043-4561-acc2-09c8c4c8cc02/verify-leaveentrieswithinternalhours.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt

echo == Times With Admin Notes or Leader Notes >> esolia-protrac-verify.txt
curl -o - http://esolia.dabbledb.com/publish/esoliaprotrac/0a8d806f-7a1d-47d4-8bde-cf61c0ea4dd8/verify-timeswithadminnotesorleadernotes.txt >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo >> esolia-protrac-verify.txt
echo ====== END ====== >> esolia-protrac-verify.txt
cat esolia-protrac-verify.txt | mail -s "eSolia Protrac Month-End Process Verifications" rick.cogley@esolia.co.jp


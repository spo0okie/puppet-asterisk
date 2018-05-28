#!/bin/sh
limit=93
echo "
delete from cdr where datediff(now(),calldate)>$limit;
delete from cdr_country_code where datediff(now(),calldate)>$limit;
delete from cdr_next where datediff(now(),calldate)>$limit;
delete from cdr_tar_part where datediff(now(),calldate)>$limit;
delete from cdr_rtp where datediff(now(),calldate)>$limit;
delete from cdr_proxy where datediff(now(),calldate)>$limit;
delete from cdr_siphistory where datediff(now(),calldate)>$limit;
delete from cdr_dtmf where datediff(now(),calldate)>$limit;
delete from cdr_sipresp where datediff(now(),calldate)>$limit;
delete from message where datediff(now(),calldate)>$limit;
delete from message_country_code where datediff(now(),calldate)>$limit;
delete from message_proxy where datediff(now(),calldate)>$limit;
delete from register_failed where datediff(now(),calldate)>$limit;
delete from register_state where datediff(now(),calldate)>$limit;
" | mysql voipmonitor
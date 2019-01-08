<?php
require("config.php"); 
$chipid = $_GET['id'];

if (isset($_GET['list'])) {
	$sql = "
            select
                data.filename
            from esp as esp
                join data as data on esp.id = data.esp_id
            where 1 = 1
                and esp.chip_id = :chip_id
                and esp.`update` = 1
            order by data.boot DESC;
            ";
    $sth = $db->prepare($sql);
    $sth->bindParam(':chip_id', $chipid, PDO::PARAM_STR);
    $sth->execute();
    $sth->bindColumn('filename', $file);

    echo "{start--\n";
    while ($row = $sth->fetch(PDO::FETCH_BOUND)) {
        echo "$file\n";
    }
    echo "--end}";


}

if (isset($_GET['update'])) {
	$sql = "SELECT * FROM esp WHERE chip_id = :chip_id";
    $sth = $db->prepare($sql);
    $sth->bindParam(':chip_id', $chipid, PDO::PARAM_STR);
    $sth->execute();
    $fetch = $sth->fetch(PDO::FETCH_ASSOC);
    $result = $fetch[update];

    if ($result == 1) {
        echo "UPDATE";
        if ($_GET['update'] == 1) {
            $sql = "UPDATE `esp` SET `update`=0, update_dt=now() WHERE chip_id=:chip_id";
            $sth = $db->prepare($sql);
            $sth->execute(array(':chip_id' => $chipid));
        }
    } else {echo "";} 

    $sql = "UPDATE `esp` SET heartbeat=now() WHERE chip_id=$chipid";
    $sth = $db->prepare($sql);
    $sth->execute(array(':chip_id' => $chipid));


}

?>
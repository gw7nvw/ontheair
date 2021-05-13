SELECT UpdateGeometrySRID('docparks','WKT',0);
copy docparks ("WKT","Overlays","NaPALIS_ID","End_Date","Vested","Section","Classified","Legislatio","Recorded_A","Conservati","Control_Ma","Government","Private_Ow","Local_Purp","Type","Start_Date","Name") from '/home/mbriggs/doc-pca.csv' delimiter ',' csv HEADER
SELECT UpdateGeometrySRID('docparks','WKT',4326);
update docparks set id = "NaPALIS_ID";

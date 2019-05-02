function export_excel(filename, feature_out, session_name, feature_name)    

T1 = table(feature_out);
writetable(T1,filename,'Sheet',1,'Range','C3','WriteVariableNames',0)

T2 = table(session_name);
writetable(T2,filename,'Sheet',1,'Range','C2','WriteVariableNames',0)

T3 = table(feature_name');
writetable(T3,filename,'Sheet',1,'Range','B3','WriteVariableNames',0)

end
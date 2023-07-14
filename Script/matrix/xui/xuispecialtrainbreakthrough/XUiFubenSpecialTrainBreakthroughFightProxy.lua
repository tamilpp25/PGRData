local XUiFubenSpecialTrainBreakthroughFightProxy = XClass(nil, "XUiFubenSpecialTrainBreakthroughFightProxy")

-- 同分的都是mvp
function XUiFubenSpecialTrainBreakthroughFightProxy:RankMvp(ui, rankMvp, roundMvpTable, scoreMvpTable, stageScoreMvpTable)
    if not XTool.IsTableEmpty(scoreMvpTable) then
        for i = 1, #scoreMvpTable do
            local mvp = scoreMvpTable[i].Mvp
            if ui.ResultPlayer[mvp] then
                ui.ResultPlayer[mvp].IsScoreMvp = true
            end
        end
    end

    if not XTool.IsTableEmpty(stageScoreMvpTable) then
        for i = 1, #stageScoreMvpTable do
            local mvp = stageScoreMvpTable[i].Mvp
            if ui.ResultPlayer[mvp] then
                ui.ResultPlayer[mvp].IsStageScoreMvp = true
            end
        end
    end
end

return XUiFubenSpecialTrainBreakthroughFightProxy

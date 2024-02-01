--周年回顾列表元素中显示玩家数据的子UI的逻辑代理
local XUiGridAnniversaryReviewData=XClass(XUiNode,'XUiGridAnniversaryReviewData')

function XUiGridAnniversaryReviewData:OnStart()
    if self.BtnOpen then
        self.BtnOpen.CallBack=function()
            XDataCenter.PlayerInfoManager.RequestPlayerInfoData(XPlayer.Id,function(data)
                self.Parent.Parent.FashionData=XDataCenter.FashionManager.GetOwnFashionDataDic()
                self.Parent.Parent:OpenReportPanel()
            end)
            --[[XDataCenter.PlayerInfoManager.RequestPlayerFashionData(XPlayer.Id, function(data)
                self.Parent.Parent.FashionData=data
                self.Parent.Parent:OpenReportPanel()
            end)
            --]]
        end
    end
end

function XUiGridAnniversaryReviewData:Refresh(type,needAnimation)
    self.Type=type
    if type==XEnumConst.Anniversary.ReviewDataType.PlayerBaseData then --名称、日期、公会
        self.TxtPlayerName.text=XDataCenter.ReviewActivityManager.GetName()
        self.TxtRegisterTime.text=XDataCenter.ReviewActivityManager.GetCreateTime()
        self.TxtPlayDays.text=XUiHelper.GetText('AnniverReviewPlayDays',XDataCenter.ReviewActivityManager.GetExistDayCount())
        self.TxtGuildName.text=XDataCenter.ReviewActivityManager.GetGuildName()
    elseif type==XEnumConst.Anniversary.ReviewDataType.ActionData then --登录、血清、螺母
        self.TxtLoginDayTimes.text=XDataCenter.ReviewActivityManager.GetLoginDayTimes()
        self.TxtConsumeNut.text=XDataCenter.ReviewActivityManager.GetConsumeNut()
        self.TxtConsumeSerum.text=XDataCenter.ReviewActivityManager.GetConsumeSerum()
    elseif type==XEnumConst.Anniversary.ReviewDataType.CharaData1 then --战力、出站、辅助机
        self.TxtPowerCharaFullName.text=XDataCenter.ReviewActivityManager.GetMaxAbilityCharacterFullName()
        self.TxtPowerAbility.text=XDataCenter.ReviewActivityManager.GetMaxAbility()
        local fightCharaFullName,maxFightCount=XDataCenter.ReviewActivityManager.GetMaxFightCountCharaFullNameAndFightCount()
        self.TxtFightCharaFullName.text=fightCharaFullName
        if not maxFightCount then
            self.TxtFightAbility.gameObject:SetActiveEx(false)
        else
            self.TxtFightAbility.gameObject:SetActiveEx(true)
            self.TxtFightAbility.text=maxFightCount
        end
        
        self.TxtPartnerNum.text=XDataCenter.ReviewActivityManager.GetPartnerCount()
    elseif type==XEnumConst.Anniversary.ReviewDataType.CharaData2 then --被摸、执勤、点击、好感
        local dormFondleMoodCharaFullName,maxFondleCount=XDataCenter.ReviewActivityManager.GetDormFondleMoodCountCharaFullNameAndFightCount()
        self.TxtDormCharalName.text=dormFondleMoodCharaFullName
        if XTool.IsNumberValid(maxFondleCount) then
            self.TxtPetOrder.gameObject:SetActiveEx(true)
            self.TxtPetOrder.text=maxFondleCount
        else
            self.TxtPetOrder.gameObject:SetActiveEx(false)
        end

        local dormWorkCharaFullName,maxdormWorkCount=XDataCenter.ReviewActivityManager.GetDormWorkCountCharaFullNameAndFightCount()
        self.TxtDormWorklName.text=dormWorkCharaFullName
        if XTool.IsNumberValid(maxdormWorkCount) then
            self.TxtWorkOrder.gameObject:SetActiveEx(true)
            self.TxtWorkOrder.text=maxdormWorkCount
        else
            self.TxtWorkOrder.gameObject:SetActiveEx(false)
        end
        local maxTouchCharaFullName,maxTouchCount=XDataCenter.ReviewActivityManager.GetTouchCountCharaFullNameAndFightCount()
        self.TxtAssistantCharalName.text=maxTouchCharaFullName
        if XTool.IsNumberValid(maxTouchCount) then
            self.TxtClickOrder.gameObject:SetActiveEx(true)
            self.TxtClickOrder.text=maxTouchCount
        else
            self.TxtClickOrder.gameObject:SetActiveEx(false)
        end
        self.TxtCharaLoveNum.text=XDataCenter.ReviewActivityManager.GetMaxTrustLvCharacterCnt()
        self.TxtCharaLove.text=XDataCenter.ReviewActivityManager.GetMaxTrustName()
    elseif type==XEnumConst.Anniversary.ReviewDataType.ActivityProcess1 then --主线、公约
        local stage,stageName=XDataCenter.ReviewActivityManager.GetMainLineStage()
        self.TxtMainLineName.text=XUiHelper.GetText('AnniverReviewMainLineProcess',stage,stageName)
        self.TxtAwareness1Name.text=XDataCenter.ReviewActivityManager.GetAssignSchedule()
        local passStageCount=XDataCenter.ReviewActivityManager.GetAwarenessSchedule()
        local totalStageCount=XTool.GetTableCount(XFubenAwarenessConfigs.GetAllConfigs(XFubenAwarenessConfigs.TableKey.AwarenessChapter))
        self.TxtAwareness2Name.text=XUiHelper.GetText('AnniverReviewAwarenessProcess',passStageCount,totalStageCount)
    elseif type==XEnumConst.Anniversary.ReviewDataType.ActivityProcess2 then --战区、囚笼
        local levelResult=XDataCenter.ReviewActivityManager.GetArenaChallengeMaxLevelCount()
        if XTool.IsTableEmpty(levelResult) then
            XLog.Error('没有战区结算段位数据')
        else
            --段位个数控制
            self.TxtArenaNum1.gameObject:SetActiveEx(#levelResult>=1)
            self.TxtArenaNum2.gameObject:SetActiveEx(#levelResult>=2)
            --依次显示
            if levelResult[1] then
                self.TxtArenaNum1.text=levelResult[1].Count
                self.TxtArenaRank1.text=XArenaConfigs.GetArenaLevelCfgByLevel(levelResult[1].ArenaLevel).Name
            end
            if levelResult[2] then
                self.TxtArenaNum2.text=levelResult[2].Count
                self.TxtArenaRank2.text=XArenaConfigs.GetArenaLevelCfgByLevel(levelResult[2].ArenaLevel).Name
            end
        end

        self.TxtFubenBossSingleScore.text=XDataCenter.ReviewActivityManager.GetBossSingleMaxScore()
        
    elseif type==XEnumConst.Anniversary.ReviewDataType.Reward1 then--勋章
        if not self.DynamicTable then
            self.DynamicTable=XDynamicTableNormal.New(self.PanelMedalScroll)
            self.DynamicTable:SetDelegate(self)
            self.DynamicTable:SetProxy(require('XUi/XUiAnniversary/XUiGridAnniversaryReviewMedal'),self)
            self.GridMedal.gameObject:SetActiveEx(false)
        end
        self.DynamicTable:SetDataSource(XDataCenter.ReviewActivityManager.GetMedalInfos())
        self.DynamicTable:ReloadDataSync()
    elseif type==XEnumConst.Anniversary.ReviewDataType.Reward2 then --藏品
        if not self.DynamicTable then
            self.DynamicTable=XDynamicTableNormal.New(self.PanelCollectionScroll)
            self.DynamicTable:SetDelegate(self)
            self.DynamicTable:SetProxy(require('XUi/XUiAnniversary/XUiGridAnniversaryReviewCollect'),self)
            self.GridCollection002.gameObject:SetActiveEx(false)
        end
        self.DynamicTable:SetDataSource(XDataCenter.ReviewActivityManager.GetScoreTitlesIdList())
        self.DynamicTable:ReloadDataSync()
    end


    if needAnimation then
        self:PlayAnimationWithMask(self.GameObject.name..'Enable')
    end
end

function XUiGridAnniversaryReviewData:OnDynamicTableEvent(event,index,grid)
    if event==DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.Type==XEnumConst.Anniversary.ReviewDataType.Reward1 then
            grid:Refresh(self.DynamicTable.DataSource[index])
        elseif self.Type==XEnumConst.Anniversary.ReviewDataType.Reward2 then
            local data=XDataCenter.MedalManager.GetScoreTitleById(self.DynamicTable.DataSource[index])
            grid:Refresh(data)
        end
    end
end

return XUiGridAnniversaryReviewData
-- 职位变更、审批设置、改名
local XUiGuildChangePosition = XLuaUiManager.Register(XLuaUi, "UiGuildChangePosition")
local NameLenMinLimit
local NameLenMaxLimit
local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiGuildChangePosition:OnStart(tipsType, targetMember)
    self.TargetMember = targetMember
    self.TipsType = tipsType
    self.PanelApply.gameObject:SetActiveEx(false)
    self.PanelPosition.gameObject:SetActiveEx(false)
    self.PanelSetName.gameObject:SetActiveEx(false)
    self:InitChildView()
end

function XUiGuildChangePosition:OnGetEvents()
    return {
        XEventId.EVENT_GUILD_FILTER_FINISH,
    }
end

function XUiGuildChangePosition:OnNotify(evt, ...)
    if evt == XEventId.EVENT_GUILD_FILTER_FINISH  then
        self:OnGuildFilterFinish(...)
    end
end

function XUiGuildChangePosition:OnGuildFilterFinish(text)
    if self.IsSetName then
        self.InFGuildName.text = text
    end
end

function XUiGuildChangePosition:InitChildView()
    -- common component --
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnCancel.CallBack = function() self:OnBtnCancelClick() end
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    -- end --

    self:HandleChangePosition()
    self:HandleApplySetting()
    self:HandleSetName()
end

function XUiGuildChangePosition:OnBtnCloseClick()
    self:Close()
end

function XUiGuildChangePosition:OnBtnCancelClick()
    self:Close()
end

function XUiGuildChangePosition:Close()
    self:EmitSignal("Close", self.TargetMember)
    self.Super.Close(self)
end

function XUiGuildChangePosition:OnBtnConfirmClick()
    if not XDataCenter.GuildManager.IsGuildAdminister() then
        XUiManager.TipMsg(CSXTextManagerGetText("GuildNotAdministor"))
        self:Close()
        return
    end

    self:ConfirmChangePosition()
    self:ConfirmApplySetting()
    self:ConfirmSetName()
end

-- 修改职位
function XUiGuildChangePosition:HandleChangePosition()
    if self.TipsType ~= XGuildConfig.TipsType.ChangePosition then return end
    self.PanelPosition.gameObject:SetActiveEx(true)
    
    local myRankLevel = XDataCenter.GuildManager.GetCurRankLevel()
    local level = XDataCenter.GuildManager.GetGuildLevel()
    local positions = XGuildConfig.GetAllGuildPositions()
    -- 当前职位的人数
    local curPosAmount = XDataCenter.GuildManager.GetMyGuildPosCount()

    self.MemberPosition = {}
    -- 会长可以转移自己的职位
    if XDataCenter.GuildManager.IsGuildLeader() then
        local id = XGuildConfig.GuildRankLevel.Leader
        table.insert(self.MemberPosition,{
            Id = id,
            Name = positions[id].Name,
            RankName = XDataCenter.GuildManager.GetRankNameByLevel(id),
            CurAmount = curPosAmount[id],
            MaxAmount = XDataCenter.GuildManager.GetGuildPosCapacity(level,id),
        })
    end
    for _, v in pairs(positions) do
        if myRankLevel < v.Id then
            local data = {
                Id = v.Id,
                Name = v.Name,
                RankName = XDataCenter.GuildManager.GetRankNameByLevel(v.Id),
                CurAmount = curPosAmount[v.Id],
                MaxAmount = XDataCenter.GuildManager.GetGuildPosCapacity(level,v.Id),
            }
            table.insert(self.MemberPosition, data)
        end
    end
    self.TabPositions = {}
    local defaultSelect = 0
    local targetRankLevel = self.TargetMember.RankLevel or 0
    for i=1, #self.MemberPosition do
        if not self.TabPositions[i] then
            local tabUi = CS.UnityEngine.Object.Instantiate(self.BtnPosition.gameObject)
            tabUi.transform:SetParent(self.PanelPositionBtn.transform, false)
            local tabBtn = tabUi.transform:GetComponent("XUiButton")
            self.TabPositions[i] = tabBtn
        end
        self.TabPositions[i].gameObject:SetActiveEx(true)
        local name = (self.MemberPosition[i].RankName ~= nil) and self.MemberPosition[i].RankName or self.MemberPosition[i].Name
        self.TabPositions[i]:SetNameByGroup(0,name)
        if self.MemberPosition[i].Id < XGuildConfig.GuildRankLevel.Member then
            local state = string.format("%d/%d", self.MemberPosition[i].CurAmount, self.MemberPosition[i].MaxAmount)
            self.TabPositions[i]:SetNameByGroup(1,state)end
        if targetRankLevel == self.MemberPosition[i].Id then
            defaultSelect = i
        end
    end
    for i = #self.MemberPosition + 1, #self.TabPositions do
        self.TabPositions[i].gameObject:SetActiveEx(false)
    end
    -- 职位列表（BtnGrp）
    self.PanelPositionBtn:Init(self.TabPositions, function(index) self:OnChangePositionClick(index) end)
    if defaultSelect > 0 then
        self.PanelPositionBtn:SelectIndex(defaultSelect)
    end
end

function XUiGuildChangePosition:ConfirmChangePosition()
    if self.TipsType ~= XGuildConfig.TipsType.ChangePosition then return end

    local positionData = self.MemberPosition[self.SelectPositionIndex]
    if not (self.SelectPositionIndex and positionData and self.TargetMember )then return end
    local targetRankLevel = self.TargetMember.RankLevel or 0
    if targetRankLevel == positionData.Id then
        XUiManager.TipMsg(CSXTextManagerGetText("GuildPositionIsSame", XDataCenter.GuildManager.GetRankNameByLevel(positionData.Id)))
        return
    end
    local dialogTitle = CSXTextManagerGetText("GuildDialogTitle")
    local hint = nil
    if XGuildConfig.GuildRankLevel.Leader == positionData.Id then
        hint = "GuildPositionChangeAdminContent"
    else
        hint = "GuildPositionChangedContent"
    end
    local dialogContent = CSXTextManagerGetText(hint, XDataCenter.GuildManager.GetRankNameByLevel(positionData.Id))
    XUiManager.DialogTip(dialogTitle, dialogContent, XUiManager.DialogType.Normal, nil, function()
        XDataCenter.GuildManager.GuildChangeRank(self.TargetMember.Id, positionData.Id, function()
            self:Close()
        end)
    end)
end

-- 公会改名
function XUiGuildChangePosition:HandleSetName()
    if self.TipsType ~= XGuildConfig.TipsType.SetName then return end
    self.PanelSetName.gameObject:SetActiveEx(true)
    
    NameLenMinLimit = CS.XGame.Config:GetInt("GuildNameMinLen")
    NameLenMaxLimit = CS.XGame.Config:GetInt("GuildNameMaxLen")
    self.BtnShop.CallBack = function() self:OnBtnShop() end
    local isFree = XDataCenter.GuildManager.GetFreeChangeGuildName()
    self.BtnShop.gameObject:SetActiveEx(not isFree)
    self.TxtFreeTip.gameObject:SetActiveEx(isFree)
    self.TxtSetNameTitle.text = CSXTextManagerGetText("GuildSetNameTitle")
    self.TxtSetNameLength.text = CSXTextManagerGetText("GuildSetNameLength", NameLenMinLimit, NameLenMaxLimit)
    self.TxtFreeTip.text = CSXTextManagerGetText("GuildSetNameFree")
    self.TxtSetNameHint.text = CSXTextManagerGetText("GuildSetNameHint")
end

function XUiGuildChangePosition:ConfirmSetName()
    if self.TipsType ~= XGuildConfig.TipsType.SetName then return end
    
    local oldName = XDataCenter.GuildManager.GetGuildName()
    local guildName = self.InFGuildName.text

    -- 检测与原来名字是否相同
    if oldName == guildName then
        local typeTitle = CSXTextManagerGetText("GuildNameTitle")
        XUiManager.TipMsg(CSXTextManagerGetText("GuildChangeInformationIsSame", typeTitle))
        return
    end
    if string.match(guildName,"%s") then
        XUiManager.TipText("GuildNameSpecialTips",XUiManager.UiTipType.Wrong)
        return
    end

    local utf8Count = self.InFGuildName.textComponent.cachedTextGenerator.characterCount - 1
    if utf8Count < NameLenMinLimit then
        local text = CSXTextManagerGetText("GuildNameMinNameLengthTips",NameLenMinLimit)
        XUiManager.TipMsg(text, XUiManager.UiTipType.Wrong)
        return
    end

    if utf8Count > NameLenMaxLimit then
        local text = CSXTextManagerGetText("GuildNameMaxNameLengthTips",NameLenMaxLimit)
        XUiManager.TipMsg(text, XUiManager.UiTipType.Wrong)
        return
    end

    XDataCenter.GuildManager.GuildChangeName(guildName, function()
        self:Close()
        XUiManager.TipText("GuildSetNameSuccessTips")
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_NAME_CHANGED)
        if XDataCenter.GuildManager.GetFreeChangeGuildName() then
            XDataCenter.GuildManager.SetFreeChangeGuildNameCount()
        end
    end)
    return
end

-- 审批设置
function XUiGuildChangePosition:HandleApplySetting()
    if self.TipsType ~= XGuildConfig.TipsType.ApplySetting then return end
    self.PanelApply.gameObject:SetActiveEx(true)
    
    self.TabSettings = {}
    table.insert(self.TabSettings, self.BtnNot)
    table.insert(self.TabSettings, self.BtnSubmission)
    table.insert(self.TabSettings, self.BtnStop)
    -- 审批选项（BtnGrp）
    self.PanelApplyBtn:Init(self.TabSettings, function(index) self:OnApplySettingClick(index) end)
    local oldOption = XDataCenter.GuildManager.GetApplyOption()
    self.PanelApplyBtn:SelectIndex(oldOption)
    self.InFLimitLevel.placeholder.text = XDataCenter.GuildManager.GetMinLevelOption()
end

function XUiGuildChangePosition:ConfirmApplySetting()
    if self.TipsType ~= XGuildConfig.TipsType.ApplySetting then return end
    if not self.SelectApplySettingIndex then return end
    
    local minLevelInput = self.InFLimitLevel.text
    if not minLevelInput or minLevelInput == "" then
        minLevelInput = XDataCenter.GuildManager.GetMinLevelOption()
    end
    if tonumber(minLevelInput) <= 0 then
        XUiManager.TipMsg(CSXTextManagerGetText("GuildSettingLevelLessThanZero"))
        return
    end
    if tonumber(minLevelInput) > XPlayerManager.PlayerMaxLevel then
        XUiManager.TipMsg(CSXTextManagerGetText("GuildSettingLevelMoreThanMax", XPlayerManager.PlayerMaxLevel))
        return
    end

    XDataCenter.GuildManager.GuildChangeApplyOption(self.SelectApplySettingIndex, tonumber(minLevelInput), function()
        XUiManager.TipMsg(CSXTextManagerGetText("GuildSettingModifySucceed"))
        self:Close()
    end)
end

function XUiGuildChangePosition:OnBtnShop()
    if not XDataCenter.GuildManager.IsJoinGuild() then return end
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        -- 4001 是绩点商店的id
        XLuaUiManager.Open("UiShop", XShopManager.ShopType.Guild, nil, 4001)
    end
end

function XUiGuildChangePosition:OnApplySettingClick(index)
    self.SelectApplySettingIndex = index
end

function XUiGuildChangePosition:OnChangePositionClick(index)
    self.SelectPositionIndex = index
end
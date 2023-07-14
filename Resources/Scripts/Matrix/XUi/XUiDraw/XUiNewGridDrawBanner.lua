local XUiNewGridDrawBanner = XClass(nil, "XUiNewGridDrawBanner")

function XUiNewGridDrawBanner:Ctor(ui, data, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Data = data
    self.Base = base

    self.BtnSkipList = {}

    self:TryGetComponent()
    self:SetButtonCallBack()
    self:SetUpBottomTimes()
    self:SetUpRewardPreview()
    self:SetBannerTime()
    self:SetSwitchInfo()
    self:SetNewHandTag()
end

function XUiNewGridDrawBanner:TryGetComponent()
    if self.BtnGo then
        self.BtnGo = self.BtnGo.transform:GetComponent("XUiButton")
    end
    if self.MingyunSelectChoukacounts then
        self.MingyunSelectChoukacounts = self.MingyunSelectChoukacounts.transform:GetComponent("Text")
    end
    if self.MingyunNomalChoukacounts then
        self.MingyunNomalChoukacounts = self.MingyunNomalChoukacounts.transform:GetComponent("Text")
    end
    if self.PutongSelectChoukacounts then
        self.PutongSelectChoukacounts = self.PutongSelectChoukacounts.transform:GetComponent("Text")
    end
    if self.PutongNormalChoukacounts then
        self.PutongNormalChoukacounts = self.PutongNormalChoukacounts.transform:GetComponent("Text")
    end
    if self.PifuChoukaCounts then
        self.PifuChoukaCounts = self.PifuChoukaCounts.transform:GetComponent("Text")
    end
    if self.TimeTxt then
        self.TimeTxt = self.TimeTxt.transform:GetComponent("Text")
    end
    if self.TxtSwitch then
        self.TxtSwitch = self.TxtSwitch.transform:GetComponent("Text")
    end

    -- 隐藏所有的跳转按钮
    local index = 1
    while true do
        local btnSkip = self[string.format("BtnSkip%s", tostring(index))]
        if not btnSkip then
            break
        end
        btnSkip = btnSkip.transform:GetComponent("Button")
        btnSkip.gameObject:SetActiveEx(false)
        self.BtnSkipList[index] = btnSkip
        index = index + 1
    end
end

function XUiNewGridDrawBanner:SetButtonCallBack()
    if self.BtnGo then
        self.BtnGo.CallBack = function()
            self:OnBtnGoClick()
        end
    end

    -- 添加跳转逻辑并显示跳转按钮
    local skipList = XDrawConfigs.GetDrawSkipList(self.Data.Id)
    if skipList and next(skipList) then
        for i = 1, #skipList do
            if not self.BtnSkipList[i] then
                XLog.Warning(string.format("XUiNewGridDrawBanner:TryGetComponent()函数警告，DrawGroupId:%s 预制界面的跳转按钮不足，第%s个跳转:%s 与后面配置的跳转无法生效",
                        tostring(self.Data.Id), tostring(i), tostring(skipList[i])))
                break
            end

            self.BtnSkipList[i].CallBack = function()
                XFunctionManager.SkipInterface(skipList[i])
            end
            self.BtnSkipList[i].gameObject:SetActiveEx(true)
        end
    end
end

function XUiNewGridDrawBanner:OnBtnGoClick()
    self.Data:GoDraw(function ()
            self.Base:MarkCurNewTag()
    end)
end

function XUiNewGridDrawBanner:SetUpBottomTimes()
    if self.MingyunSelectChoukacounts then
        self.MingyunSelectChoukacounts.text = self:GetBottomText(XDrawConfigs.GroupType.Destiny)
    end
    
    if self.MingyunNomalChoukacounts then
        self.MingyunNomalChoukacounts.text = self:GetBottomText(XDrawConfigs.GroupType.Destiny)
    end
    
    if self.PutongSelectChoukacounts then
        self.PutongSelectChoukacounts.text = self:GetBottomText(XDrawConfigs.GroupType.Normal)
    end
    
    if self.PutongNormalChoukacounts then
        self.PutongNormalChoukacounts.text = self:GetBottomText(XDrawConfigs.GroupType.Normal)
    end

    if self.PifuChoukaCounts then
        self.PifuChoukaCounts.text = self.Data:GetBottomText()
    end
end

function XUiNewGridDrawBanner:GetBottomText(type)
    local relationGroupData = self.Base:GetRelationGroupData(self.Data:GetId())
    local bottomText = "———"
    local count = 0
    if relationGroupData and relationGroupData:GetGroupType() == type then
        bottomText = relationGroupData:GetBottomText()
        count = count + 1
    end
    if self.Data:GetGroupType() == type then
        bottomText = self.Data:GetBottomText()
        count = count + 1
    end
    if count == 2 then
        XLog.Error("Client/Draw/DrawGroupRelation.tab's Data Is Error: NormalGroupId and DestinyGroupId Is Same Type")
    end
    return bottomText
end

function XUiNewGridDrawBanner:SetUpRewardPreview()
    if self.Grid256 then
        local grid = XUiGridCommon.New(self.Base, self.Grid256)
        local rewardData = self.Data:GetTopRewardData()
        grid:Refresh(rewardData:GetTemplateId())
        if self.ImgGet then
            self.ImgGet.gameObject:SetActiveEx(rewardData:GetIsGeted())
        end
    end
end

function XUiNewGridDrawBanner:SetBannerTime()
    local beginTime = self.Data:GetBannerBeginTime() or 0
    local endTime = self.Data:GetBannerEndTime() or 0
    if self.TimeTxt then
        self.TimeTxt.gameObject:SetActiveEx(beginTime ~= 0 and endTime ~= 0)
        local beginTimeStr = XTime.TimestampToGameDateTimeString(beginTime, "MM/dd")
        local endTimeStr = XTime.TimestampToGameDateTimeString(endTime, "MM/dd HH:mm")
        self.TimeTxt.text = string.format("%s-%s", beginTimeStr, endTimeStr)
    end
    if self.TimeDetail then
        self.TimeDetail.gameObject:SetActiveEx(beginTime ~= 0 and endTime ~= 0)
    end
end

function XUiNewGridDrawBanner:SetNewHandTag()
    if self.PanelNewHand then
        self.PanelNewHand.gameObject:SetActiveEx(self.Data:GetMaxBottomTimes() == self.Data:GetNewHandBottomCount())
    end
    if self.PanelNewHandTop then
        self.PanelNewHandTop.gameObject:SetActiveEx(self.Data:GetMaxBottomTimes() == self.Data:GetNewHandBottomCount())
    end
end

function XUiNewGridDrawBanner:SetSwitchInfo()
    if self.TxtSwitch then
        self.TxtSwitch.text = self.Data:GetSwitchText()
    end
end

return XUiNewGridDrawBanner
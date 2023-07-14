local XUiNewGridDrawBanner = XClass(nil, "XUiNewGridDrawBanner")

function XUiNewGridDrawBanner:Ctor(ui, data, base)
    self.GameObject = ui.gameObject
    ---@type UnityEngine.RectTransform
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
    self:SetImage()
    self:SetTime()
end

function XUiNewGridDrawBanner:Refresh()
    self:SetUpBottomTimes()
    self:SetUpRewardPreview()
    self:SetBannerTime()
    self:SetSwitchInfo()
    self:SetNewHandTag()
    self:SetTime()
end

function XUiNewGridDrawBanner:TryGetComponent()
    self.PanelTime = self.Transform:FindTransform("PanelTime")
    self.PanelZs = self.Transform:FindTransformWithSplit("SafeAreaContentPane/PanelZs")
    for i = 1, 10 do
       local obj = self.Transform:FindTransform("TxtTime" .. i)
        if obj then
            self["TxtTime"..i] = obj:GetComponent("Text")
        end
    end
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
    local btnDrawRule = self.Transform:FindTransform("BtnDrawRule")
    if btnDrawRule then
        self.BtnDrawRule = btnDrawRule:GetComponent("XUiButton")
    end
    local btnSkip = self.Transform:FindTransform("BtnSkip1")
    if btnSkip then
        ---@type XUiComponent.XUiButton
        self.BtnSkip = btnSkip:GetComponent("XUiButton")
    end
    
    local bg = self.Transform:FindTransform("Bg1")
    if bg then
        ---@type UnityEngine.UI.RawImage
        self.RImgBg = bg:GetComponent("RawImage")
    end
    
    local animationEnable = self.Transform:FindTransform("AnimEnable")
    if animationEnable then
        ---@type UnityEngine.Playables.PlayableDirector
        self.AnimEnable = animationEnable:GetComponent("PlayableDirector")
    end

    local rImgRole = self.Transform:FindTransform("RImgRole")
    if rImgRole then
        ---@type UnityEngine.UI.RawImage
        self.RImgRole = rImgRole:GetComponent("RawImage")
    end

    local rImgName = self.Transform:FindTransform("RImgName")
    if rImgName then
        ---@type UnityEngine.UI.RawImage
        self.RImgName = rImgName:GetComponent("RawImage")
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

    if self.BtnDrawRule then
        self.BtnDrawRule.CallBack = function() 
            self:OnClickBtnRule()
        end
    end

    -- 添加跳转逻辑并显示跳转按钮
    local skipList = XDrawConfigs.GetDrawSkipList(self.Data.Id)
    if self.BtnSkip then
        self.BtnSkip.CallBack = function()
            XFunctionManager.SkipInterface(skipList[1])
        end
    end
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

function XUiNewGridDrawBanner:OnClickBtnRule()
    self.BtnDrawRule.interactable = false
    local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(self.Data:GetId())
    XLuaUiManager.Open("UiDrawLog",drawInfo,1,function()
        self.BtnDrawRule.interactable = true
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

function XUiNewGridDrawBanner:SetImage(imageList)
    if not imageList then
        return
    end
    if self.RImgBg then
        if imageList[1] then
            self.RImgBg.gameObject:SetActiveEx(true)
            self.RImgBg:SetRawImage(imageList[1])
        else
            self.RImgBg.gameObject:SetActiveEx(false)
        end
    end
    if self.RImgRole then
        if imageList[2] then
            self.RImgRole.gameObject:SetActiveEx(true)
            self.RImgRole:SetRawImage(imageList[2])
        else
            self.RImgRole.gameObject:SetActiveEx(false)
        end
    end
    if self.RImgName then
        if imageList[3] then
            self.RImgName.gameObject:SetActiveEx(true)
            self.RImgName:SetRawImage(imageList[3])
        else
            self.RImgName.gameObject:SetActiveEx(false)
        end
    end
    if self.BtnSkip then
        if imageList[4] then
            self.BtnSkip.gameObject:SetActiveEx(true)
            self.BtnSkip:SetRawImage(imageList[4])
        else
            self.BtnSkip.gameObject:SetActiveEx(false)
        end
    end
    if self.AnimEnable then
        self.AnimEnable.gameObject:SetActiveEx(false)
        self.AnimEnable.gameObject:SetActiveEx(true)
        --self.AnimEnable:Play()
    end
end

function XUiNewGridDrawBanner:SetTime()

    local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(self.Data:GetId())

    local beginTimeStr = drawInfo.StartTime
    local endTimeStr = drawInfo.EndTime

    if self.PanelZs then
        self.PanelZs.gameObject:SetActiveEx (beginTimeStr == 0 or endTimeStr == 0)
    end
    if not self.PanelTime then
        return
    end
    self.PanelTime.gameObject:SetActiveEx(beginTimeStr ~= 0 and endTimeStr ~= 0)
    if beginTimeStr then
        self.TxtTime1.text = XTime.TimestampToGameDateTimeString(beginTimeStr, "MM")
        self.TxtTime3.text = XTime.TimestampToGameDateTimeString(beginTimeStr, "dd")
        --self.TxtTime8.text = XTime.TimestampToGameDateTimeString(beginTimeStr, "HH") --日服小时读取结束时间不是开始时间
        --self.TxtTime10.text = XTime.TimestampToGameDateTimeString(beginTimeStr, "mm")
    end
    if endTimeStr then
        self.TxtTime5.text = XTime.TimestampToGameDateTimeString(endTimeStr, "MM")
        self.TxtTime7.text = XTime.TimestampToGameDateTimeString(endTimeStr, "dd")
        self.TxtTime8.text = XTime.TimestampToGameDateTimeString(endTimeStr, "HH") --日服小时读取结束时间不是开始时间
        self.TxtTime10.text = XTime.TimestampToGameDateTimeString(endTimeStr, "mm")
    end
end

return XUiNewGridDrawBanner
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiNewGridDrawBanner
local XUiNewGridDrawBanner = XClass(nil, "XUiNewGridDrawBanner")

local SkipToDrawLogTabIndex = {
    BaseRule = 1, -- 基础规则页
    Preview = 2, -- 掉落详情页
    EventRule = 4, -- 特定规则页
}

function XUiNewGridDrawBanner:Ctor(ui, data, base)
    self.GameObject = ui.gameObject
    ---@type UnityEngine.RectTransform
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Data = data
    ---@type XUiNewDrawMain
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
    self:InitNewDrawComponent()
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
    for i = 1, 13 do
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
    
    -- 校准活动
    local targetBtnDetails = self.Transform:FindTransformWithSplit("SafeAreaContentPane/BtnDetails")
    self.TargetBtnDetails = targetBtnDetails and targetBtnDetails:GetComponent("XUiButton") or false
    if self.TargetBtnDetails then
        self.IsMultipleUp = true
        self.TargetPanelSwitchA = self.Transform:FindTransformWithSplit("SafeAreaContentPane/PanelSwitchA")
        self.TargetPanelSwitchS = self.Transform:FindTransformWithSplit("SafeAreaContentPane/PanelSwitchS")
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
    -- 校准活动
    if self.TargetBtnDetails then
        self.TargetBtnDetails.CallBack = function()
            self:OnClickBtnTargetRule()
        end
    end

    -- 添加跳转逻辑并显示跳转按钮
    if self.BtnSkip then
        self.BtnSkip.CallBack = function()
            local skipId = XDrawConfigs.GetDrawSkip(self.DrawId)
            XFunctionManager.SkipInterface(skipId)
        end
        local skipId = XDrawConfigs.GetDrawSkip(self.DrawId)
        self.BtnSkip.gameObject:SetActiveEx(XTool.IsNumberValid(skipId))
    end

    -- if skipId and next(skipId) then
    --     for i = 2, #skipId do
    --         if not self.BtnSkipList[i] then
    --             XLog.Warning(string.format("XUiNewGridDrawBanner:TryGetComponent()函数警告，DrawGroupId:%s 预制界面的跳转按钮不足，第%s个跳转:%s 与后面配置的跳转无法生效",
    --                     tostring(self.Data.Id), tostring(i), tostring(skipId[i])))
    --             break
    --         end
    --         self.BtnSkipList[i].CallBack = function()
    --             XFunctionManager.SkipInterface(skipId[i])
    --         end
    --         self.BtnSkipList[i].gameObject:SetActiveEx(true)
    --     end
    -- end
    if self.BtnShow then
        XUiHelper.RegisterClickEvent(self, self.BtnShow, self.OnClickWeaponShow)
    end
end

function XUiNewGridDrawBanner:OnClickWeaponShow()
    local bo = not self.BtnShow:GetToggleState()
    self.BtnDrawRule.gameObject:SetActiveEx(bo)
    self.PanelNumber.gameObject:SetActiveEx(bo)
    self.Base:HideOrShowOthers(bo)
    self.PanelWeaponShow.gameObject:SetActiveEx(not bo)

    local drawSceneCfg = XDrawConfigs.GetDrawSceneCfg(self.Base.DrawInfo.Id)
    if bo then
        self.Base.DrawScene:LoadWeaponModel(tonumber(drawSceneCfg.ModelId))
        self.PanelDrag.gameObject:SetActiveEx(false)
    else
        self.Base.CurBanner:InitWeaponSwitchBtn()
        self:UpdateWeaponSwitch(drawSceneCfg)
        self.PanelDrag.gameObject:SetActiveEx(true)
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
    XLuaUiManager.Open("UiDrawLog",drawInfo, SkipToDrawLogTabIndex.BaseRule,function()
        self.BtnDrawRule.interactable = true
    end)
end

function XUiNewGridDrawBanner:OnClickBtnTargetRule()
    self.TargetBtnDetails.interactable = false
    local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(self.Data:GetId())
    local data = XDataCenter.DrawManager.GetDrawGroupActivityTargetInfo(drawInfo.GroupId)
    XLuaUiManager.Open("UiDrawLog",drawInfo,data and SkipToDrawLogTabIndex.EventRule or SkipToDrawLogTabIndex.BaseRule,function()
        self.TargetBtnDetails.interactable = true
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
    if self.Base:CheckIsNewDraw() then
        if self.RImgName then
            self.RImgName.gameObject:SetActiveEx(false)
        end
        return
    end
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
        if self.TxtTime1 then self.TxtTime1.text = XTime.TimestampToGameDateTimeString(beginTimeStr, "MM") end
        if self.TxtTime3 then self.TxtTime3.text = XTime.TimestampToGameDateTimeString(beginTimeStr, "dd") end
        if self.TxtTime11 then self.TxtTime11.text = XTime.TimestampToGameDateTimeString(beginTimeStr, "HH") end
        if self.TxtTime13 then self.TxtTime13.text = XTime.TimestampToGameDateTimeString(beginTimeStr, "mm") end
    end
    if endTimeStr then
        if self.TxtTime5 then self.TxtTime5.text = XTime.TimestampToGameDateTimeString(endTimeStr, "MM") end
        if self.TxtTime7 then self.TxtTime7.text = XTime.TimestampToGameDateTimeString(endTimeStr, "dd") end
        if self.TxtTime8 then self.TxtTime8.text = XTime.TimestampToGameDateTimeString(endTimeStr, "HH") end
        if self.TxtTime10 then self.TxtTime10.text = XTime.TimestampToGameDateTimeString(endTimeStr, "mm") end
    end
end

--region 武器阶段展示

function XUiNewGridDrawBanner:InitWeaponSwitchBtn()
    if not self.WeaponsSwitch then
        return
    end
    if not self.BtnSwitchModelList then
        self.BtnSwitchModelList = {
            self.WeaponsSwitchItem1,
            self.WeaponsSwitchItem2,
            self.WeaponsSwitchItem3,
            self.WeaponsSwitchItem4,
        }
        self.WeaponsSwitch:Init(self.BtnSwitchModelList, handler(self, self.OnTabBtnGroupClick))
    end
end

function XUiNewGridDrawBanner:OnTabBtnGroupClick(index)
    if self.SelectWeaponIndex == index or not self.ModelCfgList or #self.ModelCfgList <= 1 then
        return
    end
    self.SelectWeaponIndex = index
    self.Base.DrawScene:LoadWeaponModelBySwitch(self.ModelCfgList[index], self.PanelDrag)
end

function XUiNewGridDrawBanner:UpdateWeaponSwitch(drawCfg)
    local templateId = tonumber(drawCfg.ModelId)
    self.ModelCfgList = XMVCA.XEquip:GetWeaponModelCfgList(templateId, self.Base.Name, 0)
    local modelCount = #self.ModelCfgList

    local firstModelIndex = 1
    if modelCount <= firstModelIndex then
        self.PanelWeaponShow.gameObject:SetActiveEx(false)
        if modelCount == firstModelIndex then
            self.Base.DrawScene:LoadWeaponModelBySwitch(self.ModelCfgList[firstModelIndex], self.PanelDrag)
        end
    else
        self.PanelWeaponShow.gameObject:SetActiveEx(true)
        self.SelectWeaponIndex = nil
        for i, btn in ipairs(self.BtnSwitchModelList) do
            btn.gameObject:SetActiveEx(i <= modelCount)
        end
        if not self.SelectWeaponIndex and modelCount > 0 then
            self.WeaponsSwitch:SelectIndex(1)
        end
    end
end

--endregion

--region 新活动卡池

function XUiNewGridDrawBanner:InitNewDrawComponent()
    if self.DrawCollaborationNew then
        self.NewDrawUiObject = {}
        XUiHelper.InitUiClass(self.NewDrawUiObject, self.DrawCollaborationNew)
        XUiHelper.RegisterClickEvent(self, self.NewDrawUiObject.BtnChoose, self.OnBtnChooseClick)
        XUiHelper.RegisterClickEvent(self, self.NewDrawUiObject.BtnChooseEmpty, self.OnBtnChooseClick)
        XUiHelper.RegisterClickEvent(self, self.NewDrawUiObject.BtnOptionalDraw, self.OnBtnChooseClick)
    end
end

function XUiNewGridDrawBanner:UpdateNewDrawView(drawCfg, modelId)
    local drawId = drawCfg.Id
    self.DrawId = drawId

    if not self.NewDrawUiObject then
        return
    end
    local groupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.Base.GroupId)
    local hasChosen = XTool.IsNumberValid(groupInfo.UseDrawId)
    self.NewDrawUiObject.PanelChar.gameObject:SetActiveEx(hasChosen)
    self.NewDrawUiObject.PanelRole.gameObject:SetActiveEx(hasChosen)
    self.NewDrawUiObject.PanelEmpty.gameObject:SetActiveEx(not hasChosen)
    self.NewDrawUiObject.BtnChoose.gameObject:SetActiveEx(hasChosen)
    self.NewDrawUiObject.BtnChooseEmpty.gameObject:SetActiveEx(not hasChosen)
    if hasChosen then
        local targetId = tonumber(modelId or drawCfg.ModelId)
        ---@type XTableCharacter
        local config = XMVCA.XCharacter:GetCharacterTemplate(targetId)
        local elementConfig = XMVCA.XCharacter:GetCharElement(config.Element)
        self.NewDrawUiObject.TxtCareer.text = XMVCA.XCharacter:GetCareerName(config.Career)
        self.NewDrawUiObject.TxtCharName.text = config.LogName
        self.NewDrawUiObject.ImgElement:SetRawImage(elementConfig.Icon2)
        self.NewDrawUiObject.TypeNum.text = XMVCA.XCharacter:GetCharacterCodeStr(targetId)
    end
end

function XUiNewGridDrawBanner:UpdateNewDrawChar(roleUrl, isQualityShow, qualityIcon)
    if not self.NewDrawUiObject then
        return
    end
    self.NewDrawUiObject.RImgRoleNew:SetRawImage(roleUrl)
    self.NewDrawUiObject.ImgQuality.gameObject:SetActiveEx(isQualityShow)
    if isQualityShow then
        self.Base:SetUiSprite(self.NewDrawUiObject.ImgQuality, qualityIcon)
    end
end

function XUiNewGridDrawBanner:OnBtnChooseClick()
    self.Base:OnBtnOptionDrawClick()
end

--endregion

return XUiNewGridDrawBanner
local XUiTextScrolling = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")
local XUiPanelFavorabilityArchives=require("XUi/XUiFavorability/PanelFavorabilityArchives/XUiPanelFavorabilityArchives")
local XUiPanelFavorabilityShow=require("XUi/XUiFavorability/PanelFavorabilityShow/XUiPanelFavorabilityShow")
local XUiPanelFavorabilityFile=require("XUi/XUiFavorability/XUiPanelFavorabilityFile")
local XUiPanelLikeGiveGift=require("XUi/XUiFavorability/XUiPanelLikeGiveGift")

---@class XUiPanelFavorabilityMain : XUiNode
---@field DrdSort UnityEngine.UI.Dropdown
local XUiPanelFavorabilityMain = XClass(XUiNode, "XUiPanelFavorabilityMain")

local FuncType = {
    File = 1,
    Info = 2,
    Gift = 3,
    Action=4
}

local JPNText = XUiHelper.GetText("FavorabilityDropDownJPNCV")
local CNText = XUiHelper.GetText("FavorabilityDropDownCNCV")
local ENText = XUiHelper.GetText("FavorabilityDropDownENCV")
local HKText = XUiHelper.GetText("FavorabilityDropDownHKCV")

local ExpSchedule = nil
local Delay_Second = CS.XGame.ClientConfig:GetInt("FavorabilityDelaySecond") / 1000
local blue = "#87C8FF"
local white = "#ffffff"

--region 生命周期
function XUiPanelFavorabilityMain:OnStart()
    self:InitObjectActiveState()
    self:InitEvent()
    self:InitData()
    self:InitUiAfterAuto()
end

function XUiPanelFavorabilityMain:OnDisable()
    self.FavorabilityShow:UnSchedulePlay()
end
--endregion

--region 初始化

--在实例化XUiNode派生类前对各个GameObject的初始激活状态进行设置
function XUiPanelFavorabilityMain:InitObjectActiveState()
    self.CVObject.gameObject:SetActiveEx(false)
    self.DrdSort.gameObject:SetActiveEx(true)
    self.PanelFavorabilityFile.gameObject:SetActiveEx(true)
    self.PanelFavorabilityArchives.gameObject:SetActiveEx(false)
    self.PanelFavorabilityShow.gameObject:SetActiveEx(false)
    self.PanelFavorabilityGift.gameObject:SetActiveEx(false)
end

--注册各类事件
function XUiPanelFavorabilityMain:InitEvent()
    local characterId = self.Parent:GetCurrFavorabilityCharacter()

    self.RedPointFileId = self:AddRedPointEvent(self.FileRed, nil, self, { XRedPointConditions.Types.CONDITION_FAVORABILITY_PLOT }, { CharacterId = characterId })
    self.RedPointArchivesId = self:AddRedPointEvent(self.InfoRed, nil, self, { XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_INFO,XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_RUMOR }, { CharacterId = characterId })
    self.RedPointShowId = self:AddRedPointEvent(self.ActionRed, nil, self, { XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_AUDIO,XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_ACTION }, { CharacterId = characterId })

    self.BtnBack.CallBack = function() self:OnBtnReturnClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
end

--初始化局部变量
function XUiPanelFavorabilityMain:InitData()
    self.IsExpTweening = false
    self.TxtNormalPos = self.TxtFavorabilityLv.rectTransform.anchoredPosition
    self.TxtMaxPos = CS.UnityEngine.Vector2(self.TxtNormalPos.x, self.TxtNormalPos.y)
    --跟设置同步
    self.CvType = CS.XAudioManager.CvType
    self.DropMaskList = {}
    --- 设置文本后Unity会在下一帧进行宽度的自动调整，防止立即滚动遮罩宽度计算错误
    self.DropMaskTimer = nil
end

function XUiPanelFavorabilityMain:InitUiAfterAuto()
    ---@type XUiTaikoMasterFlowText
    self.CvNameTextScrolling = XUiTextScrolling.New(self.CVNameLabel, self.CVNameMask)
    ---@type XUiTaikoMasterFlowText
    self.CvLabelTextScrolling = XUiTextScrolling.New(self.TxtCV ,self.TxtCvMask)

    self.FavorabilityFile = XUiPanelFavorabilityFile.New(self.PanelFavorabilityFile, self, self.Parent)
    self.FavorabilityArchives=XUiPanelFavorabilityArchives.New(self.PanelFavorabilityArchives,self,self.Parent)
    self.FavorabilityShow=XUiPanelFavorabilityShow.New(self.PanelFavorabilityShow,self,self.Parent)
    self.FavorabilityGift = XUiPanelLikeGiveGift.New(self.PanelFavorabilityGift, self, self.Parent)

    self.FavorabilityFile:OnSelected(false)
    self.FavorabilityArchives:OnSelected(false)
    self.FavorabilityShow:OnSelected(false)
    self.FavorabilityGift:OnSelected(false)

    -- 初始化按钮
    self.BtnTabList = {}
    self.BtnTabList[FuncType.File] = self.BtnFile
    self.BtnTabList[FuncType.Info] = self.BtnInfo

    self.BtnTabList[FuncType.Gift] = self.BtnGift
    self.BtnTabList[FuncType.Action] = self.BtnAction
    self.MenuBtnGroup:Init(self.BtnTabList, function(index) self:OnBtnTabListClick(index) end)

    self.CvNameTextScrolling:Stop()
    self.CvLabelTextScrolling:Play()
    self.DrdSort.onValueChanged:AddListener(function(index) self:OnBtnCvListClick(index) end)
    self.DrdSort:SetPointerClickCallback(function() self:UpdateCvName() end)
    self.DrdSort:SetDestroyDropListCallback(function() self:OnDestroyDropList() end)

    self.CurSelectedPanel = nil
    local selected = self:GetAvailableSelectTab()
    --self:OnBtnTabListClick(selected)
    --self.CurrentSelectTab = selected
    self.MenuBtnGroup:SelectIndex(selected)
end

--endregion


function XUiPanelFavorabilityMain:UpdateResume(data)
    self._forceUpdate=true
    self.MenuBtnGroup:SelectIndex(data.SelectTab)
end

function XUiPanelFavorabilityMain:GetReleaseData()
    local currentCharacterId = self.Parent:GetCurrFavorabilityCharacter()
    return {
        SelectTab = self.CurrentSelectTab,
        CurrentCharacterId = currentCharacterId
    }
end

function XUiPanelFavorabilityMain:OnBtnCvListClick(index)
    self.CvNameTextScrolling:Stop()
    
    local option = self.DrdSort.options[index]
    self.LastCvType = self.CvType
    local currentCharacterId = self.Parent:GetCurrFavorabilityCharacter()
    if option.text == JPNText then
        self.CvType = XEnumConst.CV_TYPE.JPN
    elseif option.text == HKText then
        self.CvType = XEnumConst.CV_TYPE.HK
    elseif option.text == ENText then
        self.CvType = XEnumConst.CV_TYPE.EN
    elseif option.text == CNText then
        self.CvType = XEnumConst.CV_TYPE.CN
    end
    self.CVNameLabel.text = self._Control:GetCharacterCvByIdAndType(currentCharacterId, self.CvType)
    self.CvNameTextScrolling:Play()
    self:UpdateCvLabel()
end

function XUiPanelFavorabilityMain:OnDestroyDropList()
    if not XMVCA.XSubPackage:CheckSubpackageByCvType(self.CvType) then
        self.CvType = self.LastCvType
        self.DrdSort.value = self.LastDropValue
    end
    for _, item in pairs(self.DropMaskList) do
        item:Stop()
    end
    
    self:ClearDropListMask()
end

function XUiPanelFavorabilityMain:ClearDropListMask()
    if self.DropMaskTimer then
        XScheduleManager.UnSchedule(self.DropMaskTimer)
        self.DropMaskTimer = nil
    end
    
    self.DropMaskList = {}
end

function XUiPanelFavorabilityMain:UpdateCvName()
    self.LastDropValue = self.DrdSort.value
    local currentCharacterId = self.Parent:GetCurrFavorabilityCharacter()
    local isCollaborationCharacter = self._Control:IsCollaborationCharacter(currentCharacterId)
    local dropList = self.DrdSort.transform:FindTransform("Dropdown List")
    local content = dropList:FindTransform("Content")
    local itemList = content.gameObject:GetComponentsInChildren(typeof(CS.UnityEngine.UI.Toggle))
    local cvTextList = {}
    local cvNameMaskList = {}

    for i = 0, itemList.Length - 1 do
        local panelCVName = itemList[i].transform:FindTransform("PanelCVName")
        local textLabel = panelCVName:FindTransform("ItemLabel")
        local nameText = textLabel:GetComponent(typeof(CS.UnityEngine.UI.Text))
        local cvLabel = itemList[i].transform:FindTransform("ItemLabel")
        local cvText = cvLabel.gameObject:GetComponent(typeof(CS.UnityEngine.UI.Text))
        local nameMask = itemList[i].transform:FindTransform("PanelCVName")

        if cvText.text == JPNText then
            cvTextList[XEnumConst.CV_TYPE.JPN] = nameText
            cvNameMaskList[XEnumConst.CV_TYPE.JPN] = nameMask
        elseif cvText.text == HKText then
            cvTextList[XEnumConst.CV_TYPE.HK] = nameText
            cvNameMaskList[XEnumConst.CV_TYPE.HK] = nameMask
        elseif cvText.text == ENText then
            cvTextList[XEnumConst.CV_TYPE.EN] = nameText
            cvNameMaskList[XEnumConst.CV_TYPE.EN] = nameMask
        elseif cvText.text == CNText then
            cvTextList[XEnumConst.CV_TYPE.CN] = nameText
            cvNameMaskList[XEnumConst.CV_TYPE.CN] = nameMask
        end
    end
    
    self:ClearDropListMask()
    --是不是联动角色
    if isCollaborationCharacter then
        local cvType = self._Control:GetCollaborationCharacterCvType(currentCharacterId)

        for _, v in pairs(cvType) do
            cvTextList[v].text = self._Control:GetCharacterCvByIdAndType(currentCharacterId, v)
            self.DropMaskList[v] = XUiTextScrolling.New(cvTextList[v], cvNameMaskList[v])
        end
    else
        for _, v in pairs(XEnumConst.CV_TYPE) do
            cvTextList[v].text = self._Control:GetCharacterCvByIdAndType(currentCharacterId, v)
            self.DropMaskList[v] = XUiTextScrolling.New(cvTextList[v], cvNameMaskList[v])
        end
    end

    self.DropMaskTimer = XScheduleManager.ScheduleOnce(function()
        for _, dropMask in pairs(self.DropMaskList) do
            dropMask:Play()
        end
    end, 1000)
end

function XUiPanelFavorabilityMain:GetAvailableSelectTab()
    return FuncType.File
end

-- [刷新主界面]
function XUiPanelFavorabilityMain:RefreshDatas()
    self:UpdateDatas()
end

function XUiPanelFavorabilityMain:UpdateCvLabel()
    self.CvLabelTextScrolling:Stop()
    
    local currentCharacterId = self.Parent:GetCurrFavorabilityCharacter()
    local castName = self._Control:GetCharacterCvByIdAndType(currentCharacterId, self.CvType)
    self.CVNameLabel.text = self._Control:GetCharacterCvByIdAndType(currentCharacterId, self.CvType)
    local cast = CS.XTextManager.GetText("FavorabilityCast")
    self.TxtCVDescript.text = cast
    self.TxtCV.text = castName
    self.CvLabelTextScrolling:Play()
end

function XUiPanelFavorabilityMain:UpdateDatas()
    self.PanelMenu.gameObject:SetActiveEx(true)

    self:UpdateAllInfos()
    self:UpdateCvLabel()
end

function XUiPanelFavorabilityMain:UpdateAllInfos(doAnim)
    -- 好感度信息
    self:UpdateMainInfo(doAnim)

    -- 红点checkcheck
    self:CheckLockAndReddots()
end

function XUiPanelFavorabilityMain:UpdateMainInfo(doAnim)
    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    local curExp = tonumber(self._Control:GetCurrCharacterExp(characterId))
    local trustLv = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId)
    local name = XMVCA.XCharacter:GetCharacterName(characterId)
    local tradeName = XMVCA.XCharacter:GetCharacterTradeName(characterId)
    local isCollaborationCharacter = self._Control:IsCollaborationCharacter(characterId)
    self.TxtRoleName.text = string.format("%s %s", name, tradeName)

    local curFavorabilityTableData = XMVCA.XFavorability:GetFavorabilityTableData(characterId)
    if curFavorabilityTableData == nil then return end
    self.ImgExp.gameObject:SetActiveEx(true)

    if not doAnim then
        self.ImgExp.fillAmount = curExp / (tonumber(curFavorabilityTableData.Exp) * 1)
        self.TxtLevel.text = trustLv
    end
    self.Parent:SetUiSprite(self.ImgHeart, self._Control:GetTrustLevelIconByLevel(trustLv))
    self.TxtFavorabilityLv.text = self._Control:GetWordsWithColor(trustLv, curFavorabilityTableData.Name)--curFavorabilityTableData.Name

    --是不是联动角色
    if isCollaborationCharacter then
        local icon = self._Control:GetCollaborationCharacterIcon(characterId)
        local tip = self._Control:GetCollaborationCharacterText(characterId)
        local cvType = self._Control:GetCollaborationCharacterCvType(characterId)
        local iconPos = self._Control:GetCollaborationCharacterIconPos(characterId)
        local iconScale = self._Control:GetCollaborationCharacterIconScale(characterId)

        --联动角色是否可以使用当前设置的语言
        local hasSettingCvType = false

        --是否配置icon
        if icon then
            self.RImgCollaboration:SetRawImage(icon,function()
                self.RImgCollaboration:SetNativeSize()
                if iconScale ~= 0 then
                    self.RImgCollaboration.rectTransform.localScale = CS.UnityEngine.Vector3(iconScale, iconScale, iconScale)
                else
                    self.RImgCollaboration.rectTransform.localScale = CS.UnityEngine.Vector3.one
                end
                local x = (iconPos.X ~= 0) and iconPos.X or self.RImgCollaboration.rectTransform.anchoredPosition.x
                local y = (iconPos.Y ~= 0) and iconPos.Y or self.RImgCollaboration.rectTransform.anchoredPosition.y
                self.RImgCollaboration.rectTransform.anchoredPosition  = CS.UnityEngine.Vector2(x, y)

            end)
            self.RImgCollaboration.gameObject:SetActiveEx(true)
        else
            self.RImgCollaboration.gameObject:SetActiveEx(false)
        end
        
        local optionsTextList = {}

        self.DrdSort:ClearOptions()
        for _,v in pairs(cvType) do
            if v == self.CvType then
                hasSettingCvType = true
            end
            if v == XEnumConst.CV_TYPE.JPN then
                optionsTextList[#optionsTextList + 1] = JPNText
            elseif v == XEnumConst.CV_TYPE.CN then
                optionsTextList[#optionsTextList + 1] = CNText
            elseif v == XEnumConst.CV_TYPE.HK then
                optionsTextList[#optionsTextList + 1] = HKText
            elseif v == XEnumConst.CV_TYPE.EN then
                optionsTextList[#optionsTextList + 1] = ENText
            end
        end
        self.DrdSort:AddOptionsText(optionsTextList)
        
        if not hasSettingCvType then
            self:UpdateDropListSelect(cvType[1])
        else
            self:UpdateDropListSelect(self.CvType)
        end
    else
        local optionsTextList = {}
        
        self.DrdSort:ClearOptions()
        for _,v in pairs(XEnumConst.CV_TYPE) do
            if v == XEnumConst.CV_TYPE.JPN then
                optionsTextList[#optionsTextList + 1] = JPNText
            elseif v == XEnumConst.CV_TYPE.CN then
                optionsTextList[#optionsTextList + 1] = CNText
            elseif v == XEnumConst.CV_TYPE.HK then
                optionsTextList[#optionsTextList + 1] = HKText
            elseif v == XEnumConst.CV_TYPE.EN then
                optionsTextList[#optionsTextList + 1] = ENText
            end
        end
        self.DrdSort:AddOptionsText(optionsTextList)
        self:UpdateDropListSelect(self.CvType)
        self.RImgCollaboration.gameObject:SetActiveEx(false)
    end

    self:ResetPreviewExp()
    self:CheckExp(characterId)
    self:UpdateCvLabel()

    --队伍图标
    local teamIcon=self._Control:GetCharacterTeamIconById(self:GetCurrFavorabilityCharacter())
    if teamIcon then
        self.ImgTeamIcon:SetRawImage(teamIcon)
    else
        --读默认的透明图片
        self.ImgTeamIcon:SetRawImage(CS.XGame.ClientConfig:GetString("TrustNoData"))
    end
end

function XUiPanelFavorabilityMain:UpdateDropListSelect(cvType)
    local options = self.DrdSort.options

    for i = 0, options.Count - 1 do
        if options[i].text == JPNText and cvType == XEnumConst.CV_TYPE.JPN then
            self.DrdSort.value = i
            self.DrdSort:RefreshShownValue()
            break
        end
        if options[i].text == CNText and cvType == XEnumConst.CV_TYPE.CN then
            self.DrdSort.value = i
            self.DrdSort:RefreshShownValue()
            break
        end
        if options[i].text == HKText and cvType == XEnumConst.CV_TYPE.HK then
            self.DrdSort.value = i
            self.DrdSort:RefreshShownValue()
            break
        end
        if options[i].text == ENText and cvType == XEnumConst.CV_TYPE.EN then
            self.DrdSort.value = i
            self.DrdSort:RefreshShownValue()
            break
        end
    end
end

function XUiPanelFavorabilityMain:UpdatePreviewExp(args)
    if not args then
        self:ResetPreviewExp()
        return
    end

    local trustItems = args[1]

    --local count = args[2]
    if not trustItems then
        self:ResetPreviewExp()
        return
    end

    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    local isMax = self._Control:IsMaxFavorabilityLevel(characterId)
    if isMax then
        return
    end

    local curExp = tonumber(self._Control:GetCurrCharacterExp(characterId))

    local curFavorabilityTableData = XMVCA.XFavorability:GetFavorabilityTableData(characterId)
    if not curFavorabilityTableData then
        self:ResetPreviewExp()
        return
    end

    local favorData = self._Control:GetTrustExpById(characterId)

    local addExp = 0
    for i, var in ipairs(trustItems) do
        local favorExp = var.TrustItem.Exp
        for _, v in pairs(var.TrustItem.FavorCharacterId) do
            if v == characterId then
                favorExp = var.TrustItem.FavorExp
                break
            end
        end
        addExp = addExp + favorExp * var.Count
    end

    local totalExp = addExp + curExp
    local startLevel = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId)
    local trustLv, leftExp, levelExp = self._Control:GetFavorabilityLevel(characterId, totalExp, startLevel)

    self.ImgExp.gameObject:SetActiveEx(startLevel >= trustLv)

    self.ImgExpUp.fillAmount = leftExp / levelExp
    self.TxtLevel.text = trustLv
    self.Parent:SetUiSprite(self.ImgHeart, self._Control:GetTrustLevelIconByLevel(trustLv))
    self.TxtFavorabilityLv.text = self._Control:GetWordsWithColor(trustLv, favorData[trustLv].Name)--curFavorabilityTableData.Name
    self.TxtFavorabilityExpNum.text = string.format("<color=%s>%d</color> / %s", blue, leftExp, levelExp)


    local maxLevel = self._Control:GetMaxFavorabilityLevel(characterId)
    self.TxtFavorabilityExpNum.gameObject:SetActiveEx(maxLevel ~= trustLv)
    self.TxtFavorabilityLv.rectTransform.anchoredPosition = maxLevel ~= trustLv and self.TxtNormalPos or self.TxtMaxPos

end

function XUiPanelFavorabilityMain:ResetPreviewExp()
    self.ImgExpUp.fillAmount = 0
    self:UpdateExpNum(white)
end


function XUiPanelFavorabilityMain:UpdateExpNum(color, showExp)
    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    local curFavorabilityTableData = XMVCA.XFavorability:GetFavorabilityTableData(characterId)
    local curExp = tonumber(self._Control:GetCurrCharacterExp(characterId))
    curExp = (showExp == nil) and curExp or showExp
    self.TxtFavorabilityExpNum.gameObject:SetActiveEx(true)
    self.TxtFavorabilityLv.rectTransform.anchoredPosition = self.TxtNormalPos

    local isMax = self._Control:IsMaxFavorabilityLevel(characterId)
    if isMax then
        self.TxtFavorabilityExpNum.gameObject:SetActiveEx(false)
        self.TxtFavorabilityLv.rectTransform.anchoredPosition = self.TxtMaxPos
        curExp = 0
    end

    if curFavorabilityTableData == nil then return end
    if curFavorabilityTableData.Exp <= 0 then
        self.TxtFavorabilityExpNum.text = string.format("%d", curExp)
    else
        self.TxtFavorabilityExpNum.text = string.format("<color=%s>%d</color> / %s", color, curExp, tostring(curFavorabilityTableData.Exp))
    end
end

-- [发送检查红点事件]
function XUiPanelFavorabilityMain:CheckLockAndReddots()
    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    XRedPointManager.Check(self.RedPointFileId, { CharacterId = characterId })
    XRedPointManager.Check(self.RedPointShowId, { CharacterId = characterId })
    XRedPointManager.Check(self.RedPointArchivesId, { CharacterId = characterId })
end

-- [关闭功能按钮界面]
function XUiPanelFavorabilityMain:CloseFuncBtns()
    self.PanelMenu.gameObject:SetActiveEx(false)
    self.RImgCollaboration.gameObject:SetActiveEx(false)
    self.CvNameTextScrolling:Stop()
    self.CvLabelTextScrolling:Play()
    self.FavorabilityShow:UnScheduleAudioPlay()
    if self.CurSelectedPanel then
        self.CurSelectedPanel:SetViewActive(false)
    end
end

function XUiPanelFavorabilityMain:OpenFuncBtns()
    self:PanelCvTypeShow()
    if self.CurSelectedPanel then
        self.CurSelectedPanel:SetViewActive(true)
    end
end

-- [点击的功能是否开启，如果未开启，提示]
function XUiPanelFavorabilityMain:CheckClickIsLock(funcName)
    local isOpen = XFunctionManager.JudgeCanOpen(funcName)
    local uplockTips = XFunctionManager.GetFunctionOpenCondition(funcName)
    if not isOpen then
        XUiManager.TipError(uplockTips)
    end
    return isOpen
end



-- [打开档案]
function XUiPanelFavorabilityMain:OnBtnFileClick()
    self.Parent:OpenInformationView()
end

-- [打开剧情]
function XUiPanelFavorabilityMain:OnBtnPlotClick()
    if not self:CheckClickIsLock(XFunctionManager.FunctionName.FavorabilityStory) then return end
    self.Parent:OpenPlotView()
end

-- [打开礼物]
function XUiPanelFavorabilityMain:OnBtnGiftClick()
    if not self:CheckClickIsLock(XFunctionManager.FunctionName.FavorabilityGift) then return end
    self.Parent:OpenGiftView()
end

function XUiPanelFavorabilityMain:OnBtnTabListClick(index)
    if self.LastSelectTab then
        self.Parent:PlayBaseTabAnim()
    end
    local nextFrame=false
    if index == self.CurrentSelectTab then
        if self._forceUpdate then
            self._forceUpdate=false
            nextFrame=true
        else
            return
        end
    end


    if self.CurrentSelectTab == FuncType.Gift then
        self:UpdateMainInfo()
    end

    self.LastSelectTab = self.CurrentSelectTab
    self.CurrentSelectTab = index

    if self.CurSelectedPanel then
        self.CurSelectedPanel:OnSelected(false)
    end

    self.Parent:ChangeViewType(index)


    if index == FuncType.File then
        self.CurSelectedPanel = self.FavorabilityFile
    elseif index == FuncType.Info then
        self.CurSelectedPanel = self.FavorabilityArchives
    elseif index == FuncType.Action then
        self.CurSelectedPanel = self.FavorabilityShow
    elseif index == FuncType.Gift then
        self.CurSelectedPanel = self.FavorabilityGift
    end
    
    local selectFunc=function()
        self:PanelCvTypeShow()
        self.CurSelectedPanel:OnSelected(true)
        self.Parent:PlayAnimation('QieHuan')
    end
    
    if nextFrame then
        XScheduleManager.ScheduleNextFrame(selectFunc)
    else
        selectFunc()
    end

end

function XUiPanelFavorabilityMain:PanelCvTypeShow()
    if self.CurrentSelectTab == FuncType.Audio or self.CurrentSelectTab == FuncType.Action then
        local currentCharacterId = self.Parent:GetCurrFavorabilityCharacter()
        
        self.CvNameTextScrolling:Stop()
        self.CvLabelTextScrolling:Stop()
        self.CVNameLabel.text = self._Control:GetCharacterCvByIdAndType(currentCharacterId, self.CvType)
        self.CvNameTextScrolling:Play()
    else
        self.CvNameTextScrolling:Stop()
        self.CvLabelTextScrolling:Play()
    end
end

-- [返回]
function XUiPanelFavorabilityMain:OnBtnReturnClick()
    self.CurrentSelectTab = nil
    self.Parent:SetCurrFavorabilityCharacter(nil)
    self.Parent:Close()
end

function XUiPanelFavorabilityMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPanelFavorabilityMain:StopCvContent()
    return self.Parent:StopCvContent()
end

function XUiPanelFavorabilityMain:GetCurrFavorabilityCharacter()
    return self.Parent:GetCurrFavorabilityCharacter()
end

function XUiPanelFavorabilityMain:DoFillAmountTween(lastLevel, lastExp, totalExp, isReset)
    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    local levelUpDatas = self._Control:GetTrustExpById(characterId)
    if not levelUpDatas or not levelUpDatas[lastLevel] then
        self:UpdateAnimInfo(characterId)
        return
    end
    if isReset then
        self.ImgExp.fillAmount = 0
    else
        XLuaUiManager.SetMask(true)
    end

    self.IsExpTweening = true
    local progress = 1
    if lastExp + totalExp < levelUpDatas[lastLevel].Exp then
        progress = (lastExp + totalExp) / levelUpDatas[lastLevel].Exp
        totalExp = 0
    else
        totalExp = totalExp - (levelUpDatas[lastLevel].Exp - lastExp)
    end


    self.ImgExp.gameObject:SetActiveEx(true)

    self.ImgExp:DOFillAmount(progress, Delay_Second)
    ExpSchedule = XScheduleManager.ScheduleOnce(function()
        local maxLevel = self._Control:GetMaxFavorabilityLevel(characterId)
        if totalExp <= 0 or maxLevel == lastLevel then
            self:UpdateAnimInfo(characterId)
            self:UnScheduleExp()
        else
            self.TxtLevel.text = lastLevel + 1
            self:DoFillAmountTween(lastLevel + 1, 0, totalExp, true)
        end
    end, Delay_Second * 1000 + 20)
end

-- 动画执行不了则走这里
function XUiPanelFavorabilityMain:UpdateAnimInfo(characterId)
    local trustLv = XMVCA.XFavorability:GetCurrCharacterFavorabilityLevel(characterId)
    self.TxtLevel.text = trustLv
    self:CheckExp(characterId)
end

function XUiPanelFavorabilityMain:CheckExp(characterId)
    local isMax = self._Control:IsMaxFavorabilityLevel(characterId)
    if isMax then
        self.ImgExp.fillAmount = 0
        self.TxtFavorabilityExpNum.text = 0
        return
    end

    local curExp = tonumber(self._Control:GetCurrCharacterExp(characterId))
    if curExp <= 0 and self.ImgExp.fillAmount >= 1 then
        self.ImgExp.fillAmount = 0
    end
end

function XUiPanelFavorabilityMain:UnScheduleExp()
    if ExpSchedule then
        XScheduleManager.UnSchedule(ExpSchedule)
        ExpSchedule = nil
        self.IsExpTweening = false
        XLuaUiManager.SetMask(false)
    end
end

function XUiPanelFavorabilityMain:OnClose()
    self.FavorabilityShow:UnSchedulePlay()
    self:UnScheduleExp()
end

function XUiPanelFavorabilityMain:SetTopControlActive(isActive)
    self.TopControl.gameObject:SetActiveEx(isActive)
end

function XUiPanelFavorabilityMain:SetPanelBgActive(isActive)
    self.PanelBg.gameObject:SetActiveEx(isActive)
end

function XUiPanelFavorabilityMain:SetUiSprite(image, spriteName, callBack)
    self.Parent:SetUiSprite(image, spriteName, callBack)
end

return XUiPanelFavorabilityMain
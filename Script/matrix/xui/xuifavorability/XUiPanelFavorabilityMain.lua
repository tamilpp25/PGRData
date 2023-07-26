local XUiTextScrolling = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")

XUiPanelFavorabilityMain = XClass(nil, "XUiPanelFavorabilityMain")

local FuncType = {
    File = 1,
    Info = 2,
    Secret = 3,
    Audio = 4,
    Story = 5,
    Gift = 6,
    Action = 7,
}

local CvType = {
    JPN = 1,
    CN = 2,
    HK = 3,
    EN = 4,
}

local JPNText = XUiHelper.GetText("FavorabilityDropDownJPNCV")
local CNText = XUiHelper.GetText("FavorabilityDropDownCNCV")
local ENText = XUiHelper.GetText("FavorabilityDropDownENCV")
local HKText = XUiHelper.GetText("FavorabilityDropDownHKCV")

local ExpSchedule = nil
local Delay_Second = CS.XGame.ClientConfig:GetInt("FavorabilityDelaySecond") / 1000
local blue = "#87C8FF"
local white = "#ffffff"

function XUiPanelFavorabilityMain:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self.IsExpTweening = false
    self.TxtNormalPos = self.TxtFavorabilityLv.rectTransform.anchoredPosition
    self.TxtMaxPos = CS.UnityEngine.Vector2(self.TxtNormalPos.x, self.TxtNormalPos.y - 18)
    --跟设置同步
    self.CvType = CS.XAudioManager.CvType
    self.DropMaskList = {}
    --- 设置文本后Unity会在下一帧进行宽度的自动调整，防止立即滚动遮罩宽度计算错误
    self.DropMaskTimer = nil
    ---@type XUiTaikoMasterFlowText
    self.CvNameTextScrolling = XUiTextScrolling.New(self.CVNameLabel, self.CVNameMask)
    ---@type XUiTaikoMasterFlowText
    self.CvLabelTextScrolling = XUiTextScrolling.New(self.TxtCV ,self.TxtCvMask)
    self:InitUiAfterAuto()
end

function XUiPanelFavorabilityMain:InitUiAfterAuto()

    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()

    self.RedPointPlotId = XRedPointManager.AddRedPointEvent(self.PlotRed, nil, self, { XRedPointConditions.Types.CONDITION_FAVORABILITY_PLOT }, { CharacterId = characterId })
    self.RedPointInfoId = XRedPointManager.AddRedPointEvent(self.InfoRed, nil, self, { XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_INFO }, { CharacterId = characterId })
    self.RedPointRumorId = XRedPointManager.AddRedPointEvent(self.SecretRed, nil, self, { XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_RUMOR }, { CharacterId = characterId })
    self.RedPointAudioId = XRedPointManager.AddRedPointEvent(self.SoundRed, nil, self, { XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_AUDIO }, { CharacterId = characterId })
    self.RedPointActionId = XRedPointManager.AddRedPointEvent(self.ActionRed, nil, self, { XRedPointConditions.Types.CONDITION_FAVORABILITY_DOCUMENT_ACTION }, { CharacterId = characterId })


    self.BtnBack.CallBack = function() self:OnBtnReturnClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end


    self.FavorabilityFile = XUiPanelFavorabilityFile.New(self.PanelFavorabilityFile, self.UiRoot, self)
    self.FavorabilityInfo = XUiPanelFavorabilityInfo.New(self.PanelFavorabilityInfo, self.UiRoot, self)
    self.FavorabilityRumors = XUiPanelFavorabilityRumors.New(self.PanelFavorabilityRumors, self.UiRoot, self)
    self.FavorabilityAudio = XUiPanelFavorabilityAudio.New(self.PanelFavorabilityAudio, self.UiRoot, self)
    self.FavorabilityPlot = XUiPanelFavorabilityPlot.New(self.PanelFavorabilityPlot, self.UiRoot, self)
    self.FavorabilityGift = XUiPanelLikeGiveGift.New(self.PanelFavorabilityGift, self.UiRoot, self)
    self.FavorabilityAction = XUiPanelFavorabilityAction.New(self.PanelFavorabilityAction, self.UiRoot, self)

    self.FavorabilityFile:OnSelected(false)
    self.FavorabilityInfo:OnSelected(false)
    self.FavorabilityRumors:OnSelected(false)
    self.FavorabilityAudio:OnSelected(false)
    self.FavorabilityGift:OnSelected(false)
    self.FavorabilityPlot:OnSelected(false)
    self.FavorabilityAction:OnSelected(false)

    -- 初始化按钮
    self.BtnTabList = {}
    self.BtnTabList[FuncType.File] = self.BtnFile
    self.BtnTabList[FuncType.Info] = self.BtnInfo

    self.BtnTabList[FuncType.Secret] = self.BtnSecret
    self.BtnTabList[FuncType.Audio] = self.BtnSound
    self.BtnTabList[FuncType.Story] = self.BtnPlot
    self.BtnTabList[FuncType.Gift] = self.BtnGift
    self.BtnTabList[FuncType.Action] = self.BtnAction
    self.MenuBtnGroup:Init(self.BtnTabList, function(index) self:OnBtnTabListClick(index) end)

    self.CvNameTextScrolling:Stop()
    self.CvLabelTextScrolling:Play()
    self.CVObject.gameObject:SetActiveEx(true)
    self.DrdSort.gameObject:SetActiveEx(false)
    self.PanelCvType.gameObject:SetActiveEx(false)
    self.DrdSort.onValueChanged:AddListener(function(index) self:OnBtnCvListClick(index) end)
    self.DrdSort:SetPointerClickCallback(function() self:UpdateCvName() end)
    self.DrdSort:SetDestroyDropListCallback(function() self:OnDestroyDropList() end)

    self.CurSelectedPanel = nil
    local selected = self:GetAvailableSelectTab()
    self:OnBtnTabListClick(selected)
    self.CurrentSelectTab = selected
    self.MenuBtnGroup:SelectIndex(self.CurrentSelectTab)
end

function XUiPanelFavorabilityMain:UpdateResume(data)
    self.FavorabilityPlot:UpdateAnchoredPosition(data.AnchoredPosition)
    self.MenuBtnGroup:SelectIndex(data.SelectTab)
end

function XUiPanelFavorabilityMain:GetReleaseData()
    local anchoredPosition = self.FavorabilityPlot:GetAnchoredPosition()
    local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
    return {
        SelectTab = self.CurrentSelectTab,
        AnchoredPosition = anchoredPosition,
        CurrentCharacterId = currentCharacterId
    }
end

function XUiPanelFavorabilityMain:OnBtnCvListClick(index)
    self.CvNameTextScrolling:Stop()
    
    local option = self.DrdSort.options[index]
    local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
    
    if option.text == JPNText then
        self.CvType = CvType.JPN
    elseif option.text == HKText then
        self.CvType = CvType.HK
    elseif option.text == ENText then
        self.CvType = CvType.EN
    elseif option.text == CNText then
        self.CvType = CvType.CN
    end
    self.CVNameLabel.text = XFavorabilityConfigs.GetCharacterCvByIdAndType(currentCharacterId, self.CvType)
    self.CvNameTextScrolling:Play()
    self:UpdateCvLabel()
end

function XUiPanelFavorabilityMain:OnDestroyDropList()
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
    local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isCollaborationCharacter = XFavorabilityConfigs.IsCollaborationCharacter(currentCharacterId)
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
            cvTextList[CvType.JPN] = nameText
            cvNameMaskList[CvType.JPN] = nameMask
        elseif cvText.text == HKText then
            cvTextList[CvType.HK] = nameText
            cvNameMaskList[CvType.HK] = nameMask
        elseif cvText.text == ENText then
            cvTextList[CvType.EN] = nameText
            cvNameMaskList[CvType.EN] = nameMask
        elseif cvText.text == CNText then
            cvTextList[CvType.CN] = nameText
            cvNameMaskList[CvType.CN] = nameMask
        end
    end
    
    self:ClearDropListMask()
    --是不是联动角色
    if isCollaborationCharacter then
        local cvType = XFavorabilityConfigs.GetCollaborationCharacterCvType(currentCharacterId)

        for _, v in pairs(cvType) do
            cvTextList[v].text = XFavorabilityConfigs.GetCharacterCvByIdAndType(currentCharacterId, v)
            self.DropMaskList[v] = XUiTextScrolling.New(cvTextList[v], cvNameMaskList[v])
        end
    else
        for _, v in pairs(CvType) do
            cvTextList[v].text = XFavorabilityConfigs.GetCharacterCvByIdAndType(currentCharacterId, v)
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
    
    local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local castName = XFavorabilityConfigs.GetCharacterCvByIdAndType(currentCharacterId, self.CvType)
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
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local curExp = tonumber(XDataCenter.FavorabilityManager.GetCurrCharacterExp(characterId))
    local trustLv = XDataCenter.FavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)
    local name = XCharacterConfigs.GetCharacterName(characterId)
    local tradeName = XCharacterConfigs.GetCharacterTradeName(characterId)
    local isCollaborationCharacter = XFavorabilityConfigs.IsCollaborationCharacter(characterId)
    self.TxtRoleName.text = string.format("%s %s", name, tradeName)

    local curFavorabilityTableData = XDataCenter.FavorabilityManager.GetFavorabilityTableData(characterId)
    if curFavorabilityTableData == nil then return end
    self.ImgExp.gameObject:SetActiveEx(true)

    if not doAnim then
        self.ImgExp.fillAmount = curExp / (tonumber(curFavorabilityTableData.Exp) * 1)
        self.TxtLevel.text = trustLv
    end
    self.UiRoot:SetUiSprite(self.ImgHeart, XFavorabilityConfigs.GetTrustLevelIconByLevel(trustLv))
    self.TxtFavorabilityLv.text = XDataCenter.FavorabilityManager.GetFavorabilityColorWorld(trustLv, curFavorabilityTableData.Name)--curFavorabilityTableData.Name

    --是不是联动角色
    if isCollaborationCharacter then
        local icon = XFavorabilityConfigs.GetCollaborationCharacterIcon(characterId)
        local tip = XFavorabilityConfigs.GetCollaborationCharacterText(characterId)
        local cvType = XFavorabilityConfigs.GetCollaborationCharacterCvType(characterId)
        local iconPos = XFavorabilityConfigs.GetCollaborationCharacterIconPos(characterId)
        local iconScale = XFavorabilityConfigs.GetCollaborationCharacterIconScale(characterId)

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

        --是否配置语言提示
        if tip then
            self.TxtTips.text = tip
            self.TxtTips.gameObject:SetActiveEx(true)
        else
            self.TxtTips.gameObject:SetActiveEx(false)
        end
        
        local optionsTextList = {}

        self.DrdSort:ClearOptions()
        for _,v in pairs(cvType) do
            if v == self.CvType then
                hasSettingCvType = true
            end
            if v == CvType.JPN then
                optionsTextList[#optionsTextList + 1] = JPNText
            elseif v == CvType.CN then
                optionsTextList[#optionsTextList + 1] = CNText
            elseif v == CvType.HK then
                optionsTextList[#optionsTextList + 1] = HKText
            elseif v == CvType.EN then
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
        for _,v in pairs(CvType) do
            if v == CvType.JPN then
                optionsTextList[#optionsTextList + 1] = JPNText
            elseif v == CvType.CN then
                optionsTextList[#optionsTextList + 1] = CNText
            elseif v == CvType.HK then
                optionsTextList[#optionsTextList + 1] = HKText
            elseif v == CvType.EN then
                optionsTextList[#optionsTextList + 1] = ENText
            end
        end
        self.DrdSort:AddOptionsText(optionsTextList)
        self:UpdateDropListSelect(self.CvType)
        self.RImgCollaboration.gameObject:SetActiveEx(false)
        self.TxtTips.gameObject:SetActiveEx(false)
    end

    self:ResetPreviewExp()
    self:CheckExp(characterId)
    self:UpdateCvLabel()
end

function XUiPanelFavorabilityMain:UpdateDropListSelect(cvType)
    local options = self.DrdSort.options

    for i = 0, options.Count - 1 do
        if options[i].text == JPNText and cvType == CvType.JPN then
            self.DrdSort.value = i
            self.DrdSort:RefreshShownValue()
            break
        end
        if options[i].text == CNText and cvType == CvType.CN then
            self.DrdSort.value = i
            self.DrdSort:RefreshShownValue()
            break
        end
        if options[i].text == HKText and cvType == CvType.HK then
            self.DrdSort.value = i
            self.DrdSort:RefreshShownValue()
            break
        end
        if options[i].text == ENText and cvType == CvType.EN then
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

    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isMax = XDataCenter.FavorabilityManager.IsMaxFavorabilityLevel(characterId)
    if isMax then
        return
    end

    local curExp = tonumber(XDataCenter.FavorabilityManager.GetCurrCharacterExp(characterId))

    local curFavorabilityTableData = XDataCenter.FavorabilityManager.GetFavorabilityTableData(characterId)
    if not curFavorabilityTableData then
        self:ResetPreviewExp()
        return
    end

    local favorData = XFavorabilityConfigs.GetTrustExpById(characterId)

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
    local startLevel = XDataCenter.FavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)
    local trustLv, leftExp, levelExp = XFavorabilityConfigs.GetFavorabilityLevel(characterId, totalExp, startLevel)

    self.ImgExp.gameObject:SetActiveEx(startLevel >= trustLv)

    self.ImgExpUp.fillAmount = leftExp / levelExp
    self.TxtLevel.text = trustLv
    self.UiRoot:SetUiSprite(self.ImgHeart, XFavorabilityConfigs.GetTrustLevelIconByLevel(trustLv))
    self.TxtFavorabilityLv.text = XDataCenter.FavorabilityManager.GetFavorabilityColorWorld(trustLv, favorData[trustLv].Name)--curFavorabilityTableData.Name
    self.TxtFavorabilityExpNum.text = string.format("<color=%s>%d</color> / %s", blue, leftExp, levelExp)


    local maxLevel = XFavorabilityConfigs.GetMaxFavorabilityLevel(characterId)
    self.TxtFavorabilityExpNum.gameObject:SetActiveEx(maxLevel ~= trustLv)
    self.TxtFavorabilityLv.rectTransform.anchoredPosition = maxLevel ~= trustLv and self.TxtNormalPos or self.TxtMaxPos

end

function XUiPanelFavorabilityMain:ResetPreviewExp()
    self.ImgExpUp.fillAmount = 0
    self:UpdateExpNum(white)
end


function XUiPanelFavorabilityMain:UpdateExpNum(color, showExp)
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local curFavorabilityTableData = XDataCenter.FavorabilityManager.GetFavorabilityTableData(characterId)
    local curExp = tonumber(XDataCenter.FavorabilityManager.GetCurrCharacterExp(characterId))
    curExp = (showExp == nil) and curExp or showExp
    self.TxtFavorabilityExpNum.gameObject:SetActiveEx(true)
    self.TxtFavorabilityLv.rectTransform.anchoredPosition = self.TxtNormalPos

    local isMax = XDataCenter.FavorabilityManager.IsMaxFavorabilityLevel(characterId)
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
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    XRedPointManager.Check(self.RedPointPlotId, { CharacterId = characterId })
    XRedPointManager.Check(self.RedPointRumorId, { CharacterId = characterId })
    XRedPointManager.Check(self.RedPointAudioId, { CharacterId = characterId })
    XRedPointManager.Check(self.RedPointInfoId, { CharacterId = characterId })
    XRedPointManager.Check(self.RedPointActionId, { CharacterId = characterId })
end

-- [关闭功能按钮界面]
function XUiPanelFavorabilityMain:CloseFuncBtns()
    self.PanelMenu.gameObject:SetActiveEx(false)
    self.RImgCollaboration.gameObject:SetActiveEx(false)
    --self.PanelCvType.gameObject:SetActiveEx(false)
    self.CvNameTextScrolling:Stop()
    self.CvLabelTextScrolling:Play()
    self.DrdSort.gameObject:SetActiveEx(false)
    self.CVObject.gameObject:SetActiveEx(true)
    self.ImageCVBG.gameObject:SetActiveEx(true)
    self.FavorabilityAudio:UnScheduleAudio()

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
    self.UiRoot:OpenInformationView()
end

-- [打开剧情]
function XUiPanelFavorabilityMain:OnBtnPlotClick()
    if not self:CheckClickIsLock(XFunctionManager.FunctionName.FavorabilityStory) then return end
    self.UiRoot:OpenPlotView()
end

-- [打开礼物]
function XUiPanelFavorabilityMain:OnBtnGiftClick()
    if not self:CheckClickIsLock(XFunctionManager.FunctionName.FavorabilityGift) then return end
    self.UiRoot:OpenGiftView()
end

function XUiPanelFavorabilityMain:OnBtnTabListClick(index)
    if self.LastSelectTab then
        self.UiRoot:PlayBaseTabAnim()
    end

    if index == self.CurrentSelectTab then
        return
    end


    if self.CurrentSelectTab == FuncType.Gift then
        self:UpdateMainInfo()
    end

    self.LastSelectTab = self.CurrentSelectTab
    self.CurrentSelectTab = index

    if self.CurSelectedPanel then
        self.CurSelectedPanel:OnSelected(false)
    end

    self.UiRoot:ChangeViewType(index)


    if index == FuncType.File then
        self.CurSelectedPanel = self.FavorabilityFile
    elseif index == FuncType.Info then
        self.CurSelectedPanel = self.FavorabilityInfo
    elseif index == FuncType.Secret then
        self.CurSelectedPanel = self.FavorabilityRumors
    elseif index == FuncType.Audio then
        self.CurSelectedPanel = self.FavorabilityAudio
    elseif index == FuncType.Story then
        self.CurSelectedPanel = self.FavorabilityPlot
    elseif index == FuncType.Gift then
        self.CurSelectedPanel = self.FavorabilityGift
    elseif index == FuncType.Action then
        self.CurSelectedPanel = self.FavorabilityAction
    end

    self:PanelCvTypeShow()
    self.CurSelectedPanel:OnSelected(true)
end

function XUiPanelFavorabilityMain:PanelCvTypeShow()
    if self.CurrentSelectTab == FuncType.Audio or self.CurrentSelectTab == FuncType.Action then
        local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
        
        self.CvNameTextScrolling:Stop()
        self.CvLabelTextScrolling:Stop()
        self.DrdSort.gameObject:SetActiveEx(true)
        self.CVNameLabel.text = XFavorabilityConfigs.GetCharacterCvByIdAndType(currentCharacterId, self.CvType)
        self.CVObject.gameObject:SetActiveEx(false)
        self.ImageCVBG.gameObject:SetActiveEx(false)
        self.CvNameTextScrolling:Play()
    else
        self.CvNameTextScrolling:Stop()
        self.CvLabelTextScrolling:Play()
        self.DrdSort.gameObject:SetActiveEx(false)
        self.CVObject.gameObject:SetActiveEx(true)
        self.ImageCVBG.gameObject:SetActiveEx(true)
    end
end

-- [返回]
function XUiPanelFavorabilityMain:OnBtnReturnClick()
    self.CurrentSelectTab = nil
    self.UiRoot:SetCurrFavorabilityCharacter(nil)
    self.UiRoot:Close()
end

function XUiPanelFavorabilityMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPanelFavorabilityMain:StopCvContent()
    return self.UiRoot:StopCvContent()
end

function XUiPanelFavorabilityMain:GetCurrFavorabilityCharacter()
    return self.UiRoot:GetCurrFavorabilityCharacter()
end

function XUiPanelFavorabilityMain:DoFillAmountTween(lastLevel, lastExp, totalExp, isReset)
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local levelUpDatas = XFavorabilityConfigs.GetTrustExpById(characterId)
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
        local maxLevel = XFavorabilityConfigs.GetMaxFavorabilityLevel(characterId)
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
    local trustLv = XDataCenter.FavorabilityManager.GetCurrCharacterFavorabilityLevel(characterId)
    self.TxtLevel.text = trustLv
    self:CheckExp(characterId)
end

function XUiPanelFavorabilityMain:CheckExp(characterId)
    local isMax = XDataCenter.FavorabilityManager.IsMaxFavorabilityLevel(characterId)
    if isMax then
        self.ImgExp.fillAmount = 0
        self.TxtFavorabilityExpNum.text = 0
        return
    end

    local curExp = tonumber(XDataCenter.FavorabilityManager.GetCurrCharacterExp(characterId))
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
    self:UnScheduleExp()
    self.FavorabilityAudio:OnClose()
    self.FavorabilityAction:OnClose()
end

function XUiPanelFavorabilityMain:SetTopControlActive(isActive)
    self.TopControl.gameObject:SetActiveEx(isActive)
end


function XUiPanelFavorabilityMain:SetUiSprite(image, spriteName, callBack)
    self.UiRoot:SetUiSprite(image, spriteName, callBack)
end

return XUiPanelFavorabilityMain
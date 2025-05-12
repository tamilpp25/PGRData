local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPlayerPopupSetGender: XLuaUi
---@field PanelBtnGroup XUiButtonGroup
local XUiPlayerPopupSetGender = XLuaUiManager.Register(XLuaUi, 'UiPlayerPopupSetGender')
local XUiGridPlayerSetGenderItem = require('XUi/XUiPlayerPopupSetGender/XUiGridPlayerSetGenderItem')

function XUiPlayerPopupSetGender:OnAwake()
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnConfirm.CallBack = handler(self, self.OnBtnSubmit) 
end

function XUiPlayerPopupSetGender:OnStart()
    self.TxtWarning.text = XUiHelper.GetText('PlayerGenderSetWarningTips', XUiHelper.GetTime(CS.XGame.Config:GetInt('PlayerChangeGenderInterval'), XUiHelper.TimeFormatType.DAY_HOUR_2))
    self:InitGenderItemGroup()
    self:InitReward()
end

function XUiPlayerPopupSetGender:InitGenderItemGroup()
    local cfgs = XPlayerInfoConfigs.GetPlayerGenderCfgs()

    local itemGroup = {}
    self._GenderGrids = {}
    self.BtnGenderItem.gameObject:SetActiveEx(false)
    local defaultIndex = 0
    if not XTool.IsTableEmpty(cfgs) then
        local index = 1
        for id, v in pairs(cfgs) do
            local go = CS.UnityEngine.GameObject.Instantiate(self.BtnGenderItem, self.BtnGenderItem.transform.parent)
            local grid = XUiGridPlayerSetGenderItem.New(go, self, id, index)
            grid:Open()

            table.insert(itemGroup, grid:GetButtonCom())
            table.insert(self._GenderGrids, grid)
            if grid:GetGenderId() == XPlayer.Gender then
                defaultIndex = index
            end
            
            index = index + 1
        end
    end
    
    self.PanelBtnGroup:InitBtns(itemGroup, handler(self, self.OnGenderSelect), defaultIndex)
    if XTool.IsNumberValid(defaultIndex) then
        self.PanelBtnGroup:SelectIndex(defaultIndex)
    else
        self.BtnConfirm:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiPlayerPopupSetGender:InitReward()
    local isGetReward = XPlayerManager.IsGetGenderReward()
    self.Grid256New.gameObject:SetActiveEx(false)
    self.PanelReward.gameObject:SetActiveEx(not isGetReward)

    if isGetReward then
        return
    end
    
    local rewardId = CS.XGame.Config:GetInt('PlayerFirstSetGenderReward')
    
    if XTool.IsNumberValid(rewardId) then
        local rewardList = XRewardManager.GetRewardList(rewardId)
        if not XTool.IsTableEmpty(rewardList) then
            
            self._RewardGrids = {}
            XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, #rewardList, function(index, go)
                ---@type XUiGridCommon
                local grid = XUiGridCommon.New(nil, self.Grid256New)
                grid:Refresh(rewardList[index])
                grid:SetReceived(isGetReward)
                table.insert(self._RewardGrids, grid)
            end)
        end
    end
end

function XUiPlayerPopupSetGender:OnGenderSelect(index)
    if index == self._SelectIndex then
        return
    end
    
    self._SelectIndex = index
    local grid = self._GenderGrids[self._SelectIndex]
    if grid then
        local newGenderId = grid:GetGenderId()
        self.BtnConfirm:SetButtonState(newGenderId == XPlayer.Gender and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    else
        self.BtnConfirm:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiPlayerPopupSetGender:OnBtnSubmit()
    if XTool.IsNumberValid(self._SelectIndex) then
        local grid = self._GenderGrids[self._SelectIndex]
        if grid then
            local newGenderId = grid:GetGenderId()

            if newGenderId ~= XPlayer.Gender then
                local tipContent = XUiHelper.GetText('PlayerGenderSetCheck', XPlayerInfoConfigs.GetPlayerGenderDescById(newGenderId))
                tipContent = XUiHelper.ReplaceTextNewLine(tipContent)
                XUiManager.DialogTip(XUiHelper.GetText('TipTitle'), tipContent, nil, nil, function()
                    XPlayerManager.RequestChangePlayerGender(grid:GetGenderId(), function()
                        self:Close()
                        XUiManager.TipText('PlayerGenderSetSuccessTips')
                    end)
                end)
            else
                XUiManager.TipText('PlayerGenderSetSameTips')
            end
        end
    else
        XUiManager.TipText('PlayerGenderSetFaultNoSelectTips')
    end
end

return XUiPlayerPopupSetGender
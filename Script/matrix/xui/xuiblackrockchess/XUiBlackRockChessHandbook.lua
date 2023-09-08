local XUiGridChessHead = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridChessHead")

---@class XUiBlackRockChessHandbook : XLuaUi
---@field _Control XBlackRockChessControl
---@field _ChessHead XUiGridChessHead
local XUiBlackRockChessHandbook = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessHandbook")

local TabType = { Character = 1, Chess = 2 }

local SelectIndex = 1

function XUiBlackRockChessHandbook:OnAwake()
    self.GridHead.gameObject:SetActiveEx(false)
end

function XUiBlackRockChessHandbook:OnStart()
    self:InitCompnent()
    self.PanelTab:SelectIndex(SelectIndex)
    
    self._Control:RegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.CLOSE_BUBBLE_SKILL, handler(self, self.OnBubbleSkillClose))
end

function XUiBlackRockChessHandbook:OnDestroy()
    self._Control:UnRegisterFunc(XEnumConst.BLACK_ROCK_CHESS.EVENT_FUNC_NAME.CLOSE_BUBBLE_SKILL)
end

function XUiBlackRockChessHandbook:InitCompnent()
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    self.PanelTab:Init({ self.BtnCharacter, self.BtnChess }, function(index)
        self:OnSelectTab(index)
    end)
    
    self.IsOpenBubble = false

    self:ShowCharacterInfo()
    self:ShowChessInfo()

    local endTime = self._Control:GetActivityStopTime()
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
end

function XUiBlackRockChessHandbook:OnSelectTab(index)
    SelectIndex = index
    self.PanelCharacter.gameObject:SetActiveEx(index == TabType.Character)
    self.PanelChess.gameObject:SetActiveEx(index == TabType.Chess)
    if index == TabType.Chess then
        -- 默认选中第一枚已解锁的棋子
        if self._InitSelect then
            self.PanelChessTab:SelectIndex(self._InitSelect)
            self._InitSelect = nil
        end
    end
    self:PlayAnimation("QieHuan1")
end

function XUiBlackRockChessHandbook:ShowCharacterInfo()
    -- 显示武器图标和技能
    self:ShowWeapon()
    -- 显示角色被动技能
    self:ShowPassiveSkill()
    -- 显示角色
    self:ShowCharacter()
end

function XUiBlackRockChessHandbook:ShowChessInfo()
    -- 显示棋子
    self:ShowChess()
    -- 默认选中第一枚已解锁的棋子
    --if self._InitSelect then
    --    self.PanelChessTab:SelectIndex(self._InitSelect)
    --end
end

function XUiBlackRockChessHandbook:ShowWeapon()
    local weapons = self._Control:GetHandbookConfig(TabType.Character)
    for i = 1, 2 do
        local panelWeapon = self["PanelWeapon" .. i]
        local config = weapons[i]
        if XTool.IsTableEmpty(config) then
            panelWeapon.gameObject:SetActiveEx(false)
        else
            panelWeapon.gameObject:SetActiveEx(true)
            local weaponId = config.WeaponId
            local isWeaponUnlock = self._Control:IsWeaponUnlock(weaponId)
            local skillIds = self._Control:GetWeaponSkillIds(weaponId)
            local uiObject = {}
            XTool.InitUiObjectByUi(uiObject, panelWeapon)
            uiObject.TxtName.text = self._Control:GetWeaponName(weaponId)
            --uiObject.BtnWeapon:SetRawImage(self._Control:GetWeaponSkillIcon(weaponId))
            uiObject.BtnWeapon:SetButtonState(isWeaponUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
            local skills = { uiObject.BtnAttack, uiObject.BtnSkill1, uiObject.BtnSkill2 }
            for ii, btn in pairs(skills) do
                local skillId = skillIds[ii]
                if XTool.IsNumberValid(skillId) then
                    local isSkillUnlock = isWeaponUnlock and self._Control:IsSkillUnlock(skillId)
                    btn.gameObject:SetActiveEx(true)
                    btn:SetRawImage(self._Control:GetWeaponSkillIcon(skillId))
                    btn:SetButtonState(isSkillUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
                    local txtNum = uiObject["TxtNum" .. ii]
                    if txtNum then
                        txtNum.text = self._Control:GetWeaponSkillCost(skillId, true)
                    end
                    self:RegisterClickEvent(btn, function()
                        if self.IsOpenBubble then
                            return
                        end
                        if not isSkillUnlock then
                            XUiManager.TipMsg(self._Control:GetWeaponSkillUnlockDesc(skillId))
                            return
                        end
                        self.IsOpenBubble = true
                        XLuaUiManager.Open("UiBlackRockChessBubbleSkill", skillId, btn.transform, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON_SKILL)
                    end)
                else
                    btn.gameObject:SetActiveEx(false)
                end
            end
            self:RegisterClickEvent(uiObject.BtnWeapon, function()
                if self.IsOpenBubble then
                    return
                end
                if not isWeaponUnlock then
                    XUiManager.TipMsg(self._Control:GetWeaponUnlockDesc(weaponId))
                    return
                end
                self.IsOpenBubble = true
                XLuaUiManager.Open("UiBlackRockChessBubbleSkill", weaponId, uiObject.BtnWeapon.transform, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON)
            end)
        end
    end
end

function XUiBlackRockChessHandbook:ShowPassiveSkill()
    local passiveSKills = self._Control:GetPassiveSkill()
    for i = 1, 2 do
        local btn = self["BtnGenius" .. i]
        local skill = passiveSKills[i]
        if XTool.IsTableEmpty(skill) then
            btn.gameObject:SetActiveEx(false)
        else
            local isSkillUnlock, conditionDesc = self._Control:IsPassiveSkillUnlock(skill.Id)
            btn.gameObject:SetActiveEx(true)
            btn:SetSprite(skill.Icon)
            btn:SetButtonState(isSkillUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
            self:RegisterClickEvent(btn, function()
                if self.IsOpenBubble then
                    return
                end
                if not isSkillUnlock then
                    XUiManager.TipMsg(conditionDesc)
                    return
                end
                self.IsOpenBubble = true
                XLuaUiManager.Open("UiBlackRockChessBubbleSkill", skill.Id, btn.transform,
                        XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.CHARACTER, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_ALIGN.RIGHT)
            end)
        end
    end
end

function XUiBlackRockChessHandbook:ShowCharacter()

end

function XUiBlackRockChessHandbook:ShowChess()
    self._InitSelect = nil
    local tabs = {}
    for i = 1, 6 do
        local btn = self["BtnChess" .. i]
        local isChessUnlock = self._Control:IsChessUnlock(i)
        btn:SetButtonState(isChessUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
        table.insert(tabs, btn)
        if isChessUnlock and not self._InitSelect then
            self._InitSelect = i
        end
    end
    self.PanelChessTab:Init(tabs, function(index)
        self:OnSelectChess(index)
    end)
end

function XUiBlackRockChessHandbook:OnSelectChess(index)
    local isChessUnlock, conditionDesc = self._Control:IsChessUnlock(index)
    if not isChessUnlock then
        XUiManager.TipMsg(conditionDesc)
        return
    end
    self:PlayAnimation("QieHuan2")
    local config = self._Control:GetHandbookChessConfigByIndex(index)
    self.TxtName.text = config.Name
    self.TxtDetail.text = config.Desc
    self.TxtInterval.text = XUiHelper.GetText("BlackRockChessMoveInterval", config.Interval)
    self.RImgLegend:SetRawImage(config.MoveMapIcon)

    if not self._ChessHead then
        self._ChessHead = XUiGridChessHead.New(self.GridHead, self)
    end
    self._ChessHead:Open()
    self._ChessHead:ShowChess(index)
end

function XUiBlackRockChessHandbook:OnCheckActivity(isClose)
    if isClose then
        self._Control:OnActivityEnd()
        return
    end
end

function XUiBlackRockChessHandbook:OnBubbleSkillClose()
    self.IsOpenBubble = false
end

return XUiBlackRockChessHandbook
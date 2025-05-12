local XUiPanelHandbookRole = require("XUi/XUiBlackRockChess/XUiPanel/XUiPanelHandbookRole")

---@class XUiBlackRockChessHandbook : XLuaUi
---@field _Control XBlackRockChessControl
---@field _ChessHead XUiGridHeadCommon
---@field _PanelCharacters XUiPanelHandbookRole[]
local XUiBlackRockChessHandbook = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessHandbook")

local TabType = { Character = 1, Chess = 2 }

local SelectIndex = 1

function XUiBlackRockChessHandbook:OnAwake()
    self.GridHead.gameObject:SetActiveEx(false)
    self.PanelSpine = self.Transform:Find("FullScreenBackground/PanelSpine")
    self._PanelCharacters = {}
end

function XUiBlackRockChessHandbook:OnStart()
    self:InitView()
    self.PanelTab:SelectIndex(SelectIndex)
    self._Control:AddEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_CLOSE_BUBBLE_SKILL, self.OnBubbleSkillClose, self)
end

function XUiBlackRockChessHandbook:OnDestroy()
    self._Control:RemoveEventListener(XEventId.EVENT_BLACK_ROCK_CHESS_CLOSE_BUBBLE_SKILL, self.OnBubbleSkillClose, self)
end

function XUiBlackRockChessHandbook:InitView()
    self._TopController = XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    self.PanelTab:Init({ self.BtnCharacter, self.BtnChess }, function(index)
        self:OnSelectTab(index)
    end)

    self:ShowCharacterInfo()
    self:ShowChessInfo()

    local endTime = self._Control:GetActivityStopTime()
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))
end

function XUiBlackRockChessHandbook:OnSelectTab(index)
    SelectIndex = index
    self.PanelCharacter.gameObject:SetActiveEx(index == TabType.Character)
    if self.PanelSpine then
        self.PanelSpine.gameObject:SetActiveEx(index == TabType.Character)
    end
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
    -- 显示角色被动技能
    --self:ShowPassiveSkill()
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

--function XUiBlackRockChessHandbook:ShowPassiveSkill()
--    local passiveSKills = self._Control:GetPassiveSkill()
--    for i = 1, 3 do
--        local btn = self["BtnGenius" .. i]
--        local skillId = passiveSKills[i]
--        if not skillId then
--            btn.gameObject:SetActiveEx(false)
--            goto continue
--        end
--        local isSkillUnlock, conditionDesc = self._Control:IsPassiveSkillUnlock(skillId)
--        btn.gameObject:SetActiveEx(true)
--        btn:SetSprite(self._Control:GetBuffIcon(skillId))
--        btn:SetButtonState(isSkillUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
--        self:RegisterClickEvent(btn, function()
--            if not isSkillUnlock then
--                XUiManager.TipMsg(conditionDesc)
--                return
--            end
--            self._Control:OpenBubblePreview(skillId, btn.transform,
--                    XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.CHARACTER_SKILL, XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_ALIGN.RIGHT)
--        end)
--        
--        ::continue::
--    end
--end

function XUiBlackRockChessHandbook:ShowCharacter()
    local characters = self._Control:GetHandbookConfig(TabType.Character)
    for i, character in ipairs(characters) do
        local panel = self:GetCharacterPanel(i, character)
        panel:Open()
    end
end

function XUiBlackRockChessHandbook:GetCharacterPanel(index, character)
    local panel = self._PanelCharacters[index]
    if panel then
        return panel
    end
    local ui = self["PanelRole" .. index]
    panel = XUiPanelHandbookRole.New(ui, self, character)
    self._PanelCharacters[index] = panel
    
    return panel
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
        self._ChessHead = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHeadCommon").New(self.GridHead, self)
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
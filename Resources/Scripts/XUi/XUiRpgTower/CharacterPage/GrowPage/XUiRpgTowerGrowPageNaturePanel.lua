-- 兵法蓝图角色养成天赋树页签面板
local XUiRpgTowerGrowPageNaturePanel = XClass(nil, "XUiRpgTowerGrowPageNaturePanel")
local XUiRpgTowerGrowPageNatureItem = require("XUi/XUiRpgTower/CharacterPage/GrowPage/XUiRpgTowerGrowPageNatureItem")
local XUiRpgTowerGrowPageNatureLine = require("XUi/XUiRpgTower/CharacterPage/GrowPage/XUiRpgTowerGrowPageNatureLine")
local XUiRpgTowerItemIcon = require("XUi/XUiRpgTower/Common/XUiRpgTowerItemIcon")
local TalentPrefabPath
function XUiRpgTowerGrowPageNaturePanel:Ctor(ui, page)
    XTool.InitUiObjectByUi(self, ui)
    TalentPrefabPath = XUiConfigs.GetComponentUrl("RpgTowerTalentComponent")
    self.BtnTalentTotal.CallBack = function() self:OnClickTalentTotal() end
    self.TalentItemIcon = XUiRpgTowerItemIcon.New(self.RImgTalentPointsIcon)
end
--================
--显示面板
--================
function XUiRpgTowerGrowPageNaturePanel:ShowPanel()
    self.GameObject:SetActiveEx(true)
end
--================
--刷新面板
--================
function XUiRpgTowerGrowPageNaturePanel:RefreshData(rChara)
    if not self.Talents then self:CreateTalentTree(rChara) end
    self.RCharacter = rChara
    local talents = rChara:GetTalents()
    if not talents then return end
    for posId, talent in pairs(talents) do
        self.Talents[posId]:RefreshData(talent)
        self:SetTalentLine(talent)
    end
    self.TxtTalentPieces.text = CS.XTextManager.GetText("RpgTowerTalentPiecesDes", rChara:GetTalentPoints())
    self.TalentItemIcon:InitIcon(rChara:GetTalentItem())
end
--================
--设置天赋连线状态
--================
function XUiRpgTowerGrowPageNaturePanel:SetTalentLine(rTalent)
    local prePosIds = rTalent:GetPrePosIds()
    if prePosIds then
        for _, prePosId in pairs(prePosIds) do
            self.TalentsLine[rTalent:GetPosId()][prePosId]:SetLineState(rTalent:GetIsUnLock() and self.RCharacter:GetIsTalentUnlockByPosId(prePosId))
        end
    end
end
--================
--隐藏面板
--================
function XUiRpgTowerGrowPageNaturePanel:HidePanel()
    self.GameObject:SetActiveEx(false)
end
--================
--创建天赋树节点
--================
function XUiRpgTowerGrowPageNaturePanel:CreateTalentTree(rChara)
    self:CreateTalentsParents()
    self:CreateTalentsPoints()
    self:CreateTalentsLine()
end
--================
--初始化天赋各个根节点
--================
function XUiRpgTowerGrowPageNaturePanel:CreateTalentsParents()
    self.TalentsParents = {}
    local rootNum = self.PanelTalentRoot.transform.childCount
    for i = 1, rootNum - 1 do
        local root = self.PanelTalentRoot.transform:Find(tostring(i))
        self.TalentsParents[i] = root
    end
end
--================
--初始化所有节点
--================
function XUiRpgTowerGrowPageNaturePanel:CreateTalentsPoints()
    self.Talents = {}
    for pos, parent in pairs(self.TalentsParents) do
        local prefab = parent:LoadPrefab(TalentPrefabPath)
        local talent = XUiRpgTowerGrowPageNatureItem.New(prefab)
        self.Talents[pos] = talent
    end
end
--================
--初始化所有天赋连线
--================
function XUiRpgTowerGrowPageNaturePanel:CreateTalentsLine()
    self.TalentsLine = {}
    for pos, parent in pairs(self.TalentsParents) do
        self.TalentsLine[pos] = {}
        local prePos = XRpgTowerConfig.GetTalentPrePosIdsByTalentPosId(pos)
        for _, prePosId in pairs(prePos) do
            local lineUi = parent:Find(string.format("%d_%d", prePosId, pos))
            local line = XUiRpgTowerGrowPageNatureLine.New(lineUi, prePosId, pos)
            self.TalentsLine[pos][prePosId] = line
        end
    end
end
--================
--点击天赋汇总
--================
function XUiRpgTowerGrowPageNaturePanel:OnClickTalentTotal()
    if not self.RCharacter then return end
    XLuaUiManager.Open("UiRpgTowerCollect", self.RCharacter)
end
return XUiRpgTowerGrowPageNaturePanel
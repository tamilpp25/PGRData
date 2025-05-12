--======================================XUiGridMechanismInSet==============================
---@class XUiGridMechanismInSet
---@field _Control XMechanismActivityModel
local XUiGridMechanismInSet = XClass(XUiNode, 'XUiGridMechanismInSet')
local XUiGridMechanismBuff = require('XUi/XUiMechanismActivity/UiMechanismChapter/XUiGridMechanismBuff')

function XUiGridMechanismInSet:OnStart()
    self._BuffGrids = {}
end

---@param cfg XTableMechanismCharacter
function XUiGridMechanismInSet:Refresh(cfg)
    self.StandIcon:SetRawImage(XMVCA.XCharacter:GetCharBigHeadIcon(cfg.CharacterId))
    
    XUiHelper.RefreshCustomizedList(self.UiEffectPlayBuff.transform.parent, self.UiEffectPlayBuff, cfg.BuffIcons and #cfg.BuffIcons or 0, function(index, obj)
        if self._BuffGrids[index] then
            self._BuffGrids[index]:Refresh(cfg.Id, index, true)
        else
            local grid = XUiGridMechanismBuff.New(obj, self)
            grid:Open()
            grid:Refresh(cfg.Id, index, true)
            table.insert(self._BuffGrids, grid)
        end
    end)
end

--======================================XUiPanelMechanismInSet==============================
---@class XUiPanelMechanismInSet
local XUiPanelMechanismInSet = XClass(XUiNode, 'XUiPanelMechanismInSet')

function XUiPanelMechanismInSet:OnStart()
    self._MecahnismCharaList = {}
    self:Refresh()
end

function XUiPanelMechanismInSet:Refresh()
    local chapterId = XMVCA.XMechanismActivity:GetMechanismCurChapterIdInFight()
    if XTool.IsNumberValid(chapterId) then
        local mechanismCharacterCfgs = XMVCA.XMechanismActivity:GetMechanismCharacterCfgsByChapterId(chapterId)
        if not XTool.IsTableEmpty(mechanismCharacterCfgs) then
            XUiHelper.RefreshCustomizedList(self.GridCharacter.transform.parent, self.GridCharacter, mechanismCharacterCfgs and #mechanismCharacterCfgs or 0, function(index, obj)
                if self._MecahnismCharaList[index] then
                    self._MecahnismCharaList[index]:Refresh()
                else
                    local grid = XUiGridMechanismInSet.New(obj, self)
                    grid:Open()
                    grid:Refresh(mechanismCharacterCfgs[index])
                    table.insert(self._MecahnismCharaList, grid)
                end
            end)
        end
    end
end

return XUiPanelMechanismInSet
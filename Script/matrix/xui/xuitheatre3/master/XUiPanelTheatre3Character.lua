local XUiGridTheatre3Character = require("XUi/XUiTheatre3/Master/XUiGridTheatre3Character")

---@class XUiPanelTheatre3Character : XUiNode
---@field _Control XTheatre3Control
local XUiPanelTheatre3Character = XClass(XUiNode, "XUiPanelTheatre3Character")

function XUiPanelTheatre3Character:OnStart(callBack)
    self.CallBack = callBack
    ---@type XUiGridTheatre3Character[]
    self.GridCharacterList = {}
    self.GridEnergyList = {}
    self.CharacterGrid.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre3Character:GetCharacterGridByIndex(index)
    return self.GridCharacterList[index]
end

function XUiPanelTheatre3Character:Refresh(characterGroupId)
    self.CharacterGroupId = characterGroupId
    local groupConfig = self._Control:GetCharacterGroupById(characterGroupId)
    -- 组名称
    self.TxtTitle.text = groupConfig.GroupName
    -- 能力数量
    local energyCount = groupConfig.EnergyCost
    for i = 1, energyCount do
        local grid = self.GridEnergyList[i]
        if not grid then
            grid = i == 1 and self.ImgEnergy or XUiHelper.Instantiate(self.ImgEnergy, self.PanelEnergy)
            self.GridEnergyList[i] = grid
        end
        grid.gameObject:SetActiveEx(true)
    end
    for i = energyCount + 1, #self.GridEnergyList do
        self.GridEnergyList[i].gameObject:SetActiveEx(false)
    end

    local characterIdList = self._Control:GetCharacterIdListByGroupId(characterGroupId)
    self.GridCharacterList = self.GridCharacterList or {}
    for index, id in pairs(characterIdList) do
        local grid = self.GridCharacterList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.CharacterGrid, self.PanelGroup)
            grid = XUiGridTheatre3Character.New(go, self, self.CallBack)
            self.GridCharacterList[index] = grid
        end
        grid:Open()
        grid:Refresh(id)
        grid:ShowRed(false)
    end
    for i = #characterIdList + 1, #self.GridCharacterList do
        self.GridCharacterList[i]:Close()
    end
end

return XUiPanelTheatre3Character
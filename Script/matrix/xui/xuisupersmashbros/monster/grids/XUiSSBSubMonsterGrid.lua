
local XUiSSBSubMonsterGrid = XClass(nil, "XUiSSBSubMonsterGrid")

function XUiSSBSubMonsterGrid:Ctor(uiPrefab)
    
end

function XUiSSBSubMonsterGrid:Init(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiSSBSubMonsterGrid:Refresh(monsterId)
    local monster = XDataCenter.SuperSmashBrosManager.GetMonsterById(monsterId)
    self.MonsterImg:SetRawImage(monster:GetIcon())
    self.MonsterName.text = monster:GetName()
end

return XUiSSBSubMonsterGrid
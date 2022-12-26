local OBJECT_COUNT = 204

local XUiSuperWaterMarks = XLuaUiManager.Register(XLuaUi, "UiSuperWaterMarks")

function XUiSuperWaterMarks:OnAwake()
    self:InitUiObjects()
end

function XUiSuperWaterMarks:OnStart()

    self.TextId.text = XPlayer.Id

    if self.ObjectPool:Exist() then
        for i = 1, OBJECT_COUNT do
            self.ObjectPool:Spawn()
        end
    end

end
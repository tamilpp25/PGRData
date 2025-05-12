local XUiTempleBattleGrid = require("XUi/XUiTemple/XUiTempleBattleGrid")

---@class XUiTemplePhotoDetail : XLuaUi
---@field _Control XTempleControl
local XUiTemplePhotoDetail = XLuaUiManager.Register(XLuaUi, "UiTemplePhotoDetail")

function XUiTemplePhotoDetail:Ctor()
    self._Grids = {}
end

function XUiTemplePhotoDetail:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    
    self.ImgBackgroumd = self.ImgBackgroumd or XUiHelper.TryGetComponent(self.Checkerboard.transform.parent.transform, "ImgBackgroumd", "RawImage")
end

function XUiTemplePhotoDetail:OnStart(characterId)
    local data = self._Control:GetUiControl():GetPhotoDetailData(characterId)
    self.RImgCharater:SetRawImage(data.Icon)
    self.TxtChat.text = data.Text
    self:UpdateDynamicItem(self._Grids, data.Grids, self.GridCheckerboard, XUiTempleBattleGrid)

    if self.ImgBackgroumd then
        self.ImgBackgroumd:SetRawImage(data.Bg)
    end
end

function XUiTemplePhotoDetail:UpdateDynamicItem(gridArray, dataArray, uiObject, class)
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, #dataArray do
        local grid = gridArray[i]
        if not grid then
            local uiObject = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = class.New(uiObject, self)
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = #dataArray + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

return XUiTemplePhotoDetail
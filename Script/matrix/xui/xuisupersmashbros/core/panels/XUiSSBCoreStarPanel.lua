
local XUiSSBCoreStarPanel = XClass(nil, "XUiSSBCoreStarPanel")

function XUiSSBCoreStarPanel:Ctor(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.UnlockStarsPanel = {}
    self.NotUnlockStarsPanel = {}
    XTool.InitUiObjectByUi(self.UnlockStarsPanel, self.UnlockStars)
    XTool.InitUiObjectByUi(self.NotUnlockStarsPanel, self.NotUnlockStars)
end

function XUiSSBCoreStarPanel:ShowStar(star)
    if not star or star < 1 then return end
    for index = 1, 5 do
        local unLockImg = self.UnlockStarsPanel["Img" .. index]
        local lockImg = self.NotUnlockStarsPanel["Img" .. index]
        if unLockImg then
            unLockImg.gameObject:SetActiveEx(index <= star)
        end
        if lockImg then
            lockImg.gameObject:SetActiveEx(index > star)
        end
    end
end

return XUiSSBCoreStarPanel
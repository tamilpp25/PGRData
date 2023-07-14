local XUiGridDormCharacter = XClass(nil, "XUiGridDormCharacter")

function XUiGridDormCharacter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridDormCharacter:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridDormCharacter:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridDormCharacter:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridDormCharacter:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
end

function XUiGridDormCharacter:OnBtnClickClick()
    self.ImgNew.gameObject:SetActiveEx(false)
    XLuaUiManager.Open("UiDormCharacterDetail", self.CharacterId, self.RootUi.FromDorm)
end

function XUiGridDormCharacter:Refresh(characterId)
    self.CharacterId = characterId

    local charStyleConfig = XDormConfig.GetCharacterStyleConfigById(characterId)
    if not charStyleConfig then
        return
    end

    self.RImgIcon:SetRawImage(charStyleConfig.HeadIcon, nil, true)
    self.TxtCharacterName.text = charStyleConfig.Name
    local loveTypeConfig = XFurnitureConfigs.GetDormFurnitureType(charStyleConfig.LoveType)
    local likeTypeConfig = XFurnitureConfigs.GetDormFurnitureType(charStyleConfig.LikeType)

    self.RootUi:SetUiSprite(self.ImgLove, loveTypeConfig.TypeIcon)
    self.RootUi:SetUiSprite(self.ImgLike, likeTypeConfig.TypeIcon)

    local showNew = XDataCenter.FurnitureManager.CheckNewHint(characterId)
    self.ImgNew.gameObject:SetActiveEx(showNew)
    if showNew then
        local ids = {}
        table.insert(ids, characterId)
        XDataCenter.FurnitureManager.AddNewHint(ids)
    end

    self.TxtLove.text = CS.XTextManager.GetText("DormHightDescription")
    self.TxtLike.text = CS.XTextManager.GetText("DormMiddleDescription")

    local inRoomNumber = XDataCenter.DormManager.GetCharacterRoomNumber(characterId)
    self.PanelInRoom.gameObject:SetActiveEx(inRoomNumber > 0)
    if inRoomNumber > 0 then
        self.TxtRoomNum.text = XDataCenter.DormManager.GetDormName(inRoomNumber)
    end
end

return XUiGridDormCharacter
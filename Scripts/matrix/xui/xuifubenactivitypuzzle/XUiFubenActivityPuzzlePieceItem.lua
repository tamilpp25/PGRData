local tableInsert = table.insert

local XUiFubenActivityPuzzlePieceItem = XClass(nil, "XUiFubenActivityPuzzlePieceItem")

function XUiFubenActivityPuzzlePieceItem:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiFubenActivityPuzzlePieceItem:Init()
    self.PuzzleImgItem.gameObject:SetActiveEx(false)
end

function XUiFubenActivityPuzzlePieceItem:SetRawImage(path)
    self.RawImage:SetRawImage(path)
end

function XUiFubenActivityPuzzlePieceItem:SetActive(bool)
    self.PuzzleImgItem.gameObject:SetActiveEx(bool)
end

function XUiFubenActivityPuzzlePieceItem:SetCorrect(isCorrect)
    if isCorrect then
        self.CorrectItem.gameObject:SetActiveEx(true)
        self.MistakeItem.gameObject:SetActiveEx(false)
    else
        self.CorrectItem.gameObject:SetActiveEx(false)
        self.MistakeItem.gameObject:SetActiveEx(true)
    end
end

function XUiFubenActivityPuzzlePieceItem:SetLight(isLight)
    self.LightItem.gameObject:SetActiveEx(isLight)
end

function XUiFubenActivityPuzzlePieceItem:ShowMistakeEffect()
    self.MistakeEffect.gameObject:SetActiveEx(false)
    self.MistakeEffect.gameObject:SetActiveEx(true)
    XSoundManager.PlaySoundByType(1115, XSoundManager.SoundType.Sound)
end

function XUiFubenActivityPuzzlePieceItem:ShowCorrectEffect()
    self.CorrectEffect.gameObject:SetActiveEx(false)
    self.CorrectEffect.gameObject:SetActiveEx(true)
    XSoundManager.PlaySoundByType(1114, XSoundManager.SoundType.Sound)
end

function XUiFubenActivityPuzzlePieceItem:ShowAwardEffect(isShow)
    self.AwardItem.gameObject:SetActiveEx(isShow)
end

function XUiFubenActivityPuzzlePieceItem:HideCorrectAndMistakeEffect()
    self.CorrectEffect.gameObject:SetActiveEx(false)
    self.MistakeEffect.gameObject:SetActiveEx(false)
end

return XUiFubenActivityPuzzlePieceItem
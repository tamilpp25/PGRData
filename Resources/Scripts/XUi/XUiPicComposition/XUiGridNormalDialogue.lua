XUiGridNormalDialogue = XClass(nil, "XUiGridNormalDialogue")
local EditIcon = CS.XGame.ClientConfig:GetString("PicCompositionEditIcon")

function XUiGridNormalDialogue:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base

    XTool.InitUiObject(self)
end


function XUiGridNormalDialogue:Update(dialogueData)
    self.TxtWord.text = ""
    self.ImgHead:SetRawImage(EditIcon)

    if dialogueData then
        if dialogueData.CharacterId then
            local info = XMarketingActivityConfigs.GetCompositionCharacterConfigById(dialogueData.CharacterId)
            if info then
                self.ImgHead:SetRawImage(info.Icon)
                self.TxtName.text = info.Name
            end
        end
        if dialogueData.Content then
            self.TxtWord.text = dialogueData.Content
        end
        self.GameObject:SetActiveEx(true)
    else
        self.GameObject:SetActiveEx(false)
    end
end


local XDlcHuntDebug = {}

function XDlcHuntDebug.Hack()
    if not XNetwork.OriginalCall then
        XNetwork.OriginalCall = XNetwork.Call
    end
    XNetwork.Call = function(handler, request, reply, isEncoded, exReply, shieldReply)
        if handler == "DlcCreateRoomRequest" then
            XScheduleManager.ScheduleOnce(function()
                reply(XDlcHuntDebug.CreateRoom(request))
            end, 0)
            return
        end
        if handler == "DlcMatchRoomRequest" then
            XScheduleManager.ScheduleOnce(function()
                reply({ Code = XCode.Success })
            end, 0)
            return
        end
        if handler == "DlcSetAutoMatchRequest" then
            XScheduleManager.ScheduleOnce(function()
                XDataCenter.DlcRoomManager.OnRoomInfoUpdate({
                    AutoMatch = request.AutoMatch
                })
            end, 0)
            return
        end
        if handler == "DlcSelectRequest" then
            XScheduleManager.ScheduleOnce(function()
                local member = XDataCenter.DlcRoomManager.GetTeam():GetSelfMember()
                XDataCenter.DlcRoomManager.OnPlayerInfoUpdate({
                    PlayerInfoList = {
                        {
                            Id = member:GetPlayerId(),
                            Leader = member:IsLeader(),
                            State = member:GetReadyState(),
                            FightNpcData = {
                                Id = request.CharacterId,
                                PowerGroupList = {},
                                CreateTime = 0,
                                Ability = member:GetAbility()
                            }
                        },
                    }
                })
            end, 0)
            return
        end
        XNetwork.OriginalCall(handler, request, reply, isEncoded, exReply, shieldReply)
    end
    print("Hack DlcHunt--------------------------")
end

function XDlcHuntDebug.CreateRoom(request)
    local allCharacter = XDataCenter.DlcHuntCharacterManager.GetCharacterList()
    local character1 = allCharacter[1]
    local character2 = allCharacter[2]
    return {
        Code = XCode.Success,
        RoomData = {
            Id = 989,
            WorldId = 1,
            IsOnline = true,
            AutoMatch = true,
            State = XDataCenter.RoomManager.RoomState.Normal,
            AbilityLimit = 3,
            PlayerDataList = {
                {
                    Id = 10001,
                    Name = "RogOP521",
                    Level = 1,
                    Leader = false,
                    HeadPortraitId = 0,
                    HeadFrameId = 0,
                    MedalId = 0,
                    State = XDlcHuntConfigs.PlayerState.Ready,
                    WorldNpcData = {
                        Character = {
                            Id = character1:GetCharacterId(),
                            Level = 1,
                            PowerGroupList = {},
                            CreateTime = 0,
                            Ability = 1
                        }
                    }
                },
                {
                    Id = XPlayer.Id,
                    Name = XPlayer.Name,
                    Level = 1,
                    Leader = true,
                    HeadPortraitId = 0,
                    HeadFrameId = 0,
                    MedalId = 0,
                    State = XDlcHuntConfigs.PlayerState.Normal,
                    WorldNpcData = {
                        Character = {
                            Id = XDataCenter.DlcHuntCharacterManager.GetFightCharacterId(),
                            Level = 1,
                            PowerGroupList = {},
                            CreateTime = 0,
                            Ability = 1
                        }
                    }
                },
            }
        }
    }
end

return XDlcHuntDebug
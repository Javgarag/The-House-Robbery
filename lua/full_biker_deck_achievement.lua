return function(instigator)
    local equipped_team = {
        perk_deck = 16
    }

    local function award(package_id, achievement_id)
        local package = CustomAchievementPackage:new(package_id)
        local achievement = package:Achievement(achievement_id)
        achievement:Unlock()
    end

    for _, peer in pairs(managers.network:session():all_peers()) do
        if not ChallengeManager:check_equipped_outfit(equipped_team, peer:blackmarket_outfit(), peer:character()) then
            return
        end
        award("house_robbery", "hogar_tag_team")
    end

end
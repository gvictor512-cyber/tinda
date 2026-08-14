"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CompatibilityCalculator = void 0;
class CompatibilityCalculator {
    constructor() {
        this.weights = {
            schedule: 0.15,
            cleanliness: 0.20,
            smoking: 0.15,
            pets: 0.10,
            personality: 0.15,
            guests: 0.05,
            cooking: 0.05,
            music: 0.05,
            workFromHome: 0.10,
        };
    }
    calculate(user1, user2) {
        const factors = [];
        factors.push(this.calculateScheduleCompatibility(user1.settings, user2.settings));
        factors.push(this.calculateCleanlinessCompatibility(user1.settings, user2.settings));
        factors.push(this.calculateSmokingCompatibility(user1.settings, user2.settings));
        factors.push(this.calculatePetsCompatibility(user1.settings, user2.settings));
        factors.push(this.calculatePersonalityCompatibility(user1.settings, user2.settings));
        factors.push(this.calculateGuestsCompatibility(user1.settings, user2.settings));
        factors.push(this.calculateCookingCompatibility(user1.settings, user2.settings));
        factors.push(this.calculateMusicCompatibility(user1.settings, user2.settings));
        factors.push(this.calculateWorkFromHomeCompatibility(user1.settings, user2.settings));
        const totalScore = factors.reduce((sum, factor) => sum + factor.contribution, 0);
        const explanation = this.generateExplanation(factors, totalScore);
        return {
            score: Math.round(totalScore),
            explanation,
            factors,
        };
    }
    calculateScheduleCompatibility(s1, s2) {
        const weight = this.weights.schedule;
        let score = 0;
        let details = '';
        const compatibleSchedules = {
            madrugador: ['madrugador', 'estudiante'],
            nocturno: ['nocturno', 'estudiante'],
            trabajo_remoto: ['trabajo_remoto', 'madrugador'],
            turnos: ['turnos', 'nocturno'],
            estudiante: ['estudiante', 'madrugador', 'nocturno'],
        };
        if (!s1.scheduleType || !s2.scheduleType) {
            score = 50;
            details = 'Horarios no especificados';
        }
        else if (s1.scheduleType === s2.scheduleType) {
            score = 100;
            details = 'Tenéis el mismo tipo de horario';
        }
        else if (compatibleSchedules[s1.scheduleType]?.includes(s2.scheduleType)) {
            score = 75;
            details = 'Vuestros horarios son compatibles';
        }
        else {
            score = 30;
            details = 'Vuestros horarios podrían chocar';
        }
        return {
            factor: 'Horarios',
            weight,
            score,
            contribution: weight * score,
            details,
        };
    }
    calculateCleanlinessCompatibility(s1, s2) {
        const weight = this.weights.cleanliness;
        let score = 0;
        let details = '';
        const level1 = s1.cleanlinessLevel || 3;
        const level2 = s2.cleanlinessLevel || 3;
        const diff = Math.abs(level1 - level2);
        if (diff === 0) {
            score = 100;
            details = '_tenéis el mismo nivel de exigencia con la limpieza';
        }
        else if (diff === 1) {
            score = 80;
            details = 'Niveles de limpieza muy similares';
        }
        else if (diff === 2) {
            score = 60;
            details = 'Diferencia moderada en limpieza';
        }
        else {
            score = 30;
            details = 'Diferencia significativa en limpieza';
        }
        return {
            factor: 'Limpieza',
            weight,
            score,
            contribution: weight * score,
            details,
        };
    }
    calculateSmokingCompatibility(s1, s2) {
        const weight = this.weights.smoking;
        let score = 0;
        let details = '';
        const pref1 = s1.smokingPreference || 'no_fuma';
        const pref2 = s2.smokingPreference || 'no_fuma';
        if (pref1 === pref2) {
            score = 100;
            details = pref1 === 'no_fuma' ? 'Ambos no fumáis' : 'Tenéis el mismo hábito con el tabaco';
        }
        else if (pref1 === 'no_fuma' && pref2 === 'fuma_fuera') {
            score = 85;
            details = 'Uno no fuma y el otro fuma fuera';
        }
        else if (pref2 === 'no_fuma' && pref1 === 'fuma_fuera') {
            score = 85;
            details = 'Uno no fuma y el otro fuma fuera';
        }
        else if (pref1 === 'fuma_dentro' || pref2 === 'fuma_dentro') {
            score = 20;
            details = 'Incompatibilidad: uno fuma dentro';
        }
        else {
            score = 50;
            details = 'Diferentes preferencias sobre tabaco';
        }
        return {
            factor: 'Tabaco',
            weight,
            score,
            contribution: weight * score,
            details,
        };
    }
    calculatePetsCompatibility(s1, s2) {
        const weight = this.weights.pets;
        let score = 0;
        let details = '';
        const pref1 = s1.petsPreference || 'me_encantan';
        const pref2 = s2.petsPreference || 'me_encantan';
        if (pref1 === 'soy_alergico' && (pref2 === 'tengo_mascotas' || pref2 === 'me_encantan')) {
            score = 0;
            details = 'Incompatible: uno es alérgico';
        }
        else if (pref2 === 'soy_alergico' && (pref1 === 'tengo_mascotas' || pref1 === 'me_encantan')) {
            score = 0;
            details = 'Incompatible: uno es alérgico';
        }
        else if (pref1 === 'no_quiero_mascotas' && pref2 === 'tengo_mascotas') {
            score = 20;
            details = 'Conflicto: uno tiene mascotas y el otro no quiere';
        }
        else if (pref2 === 'no_quiero_mascotas' && pref1 === 'tengo_mascotas') {
            score = 20;
            details = 'Conflicto: uno tiene mascotas y el otro no quiere';
        }
        else if (pref1 === pref2) {
            score = 100;
            details = 'Misma opinión sobre mascotas';
        }
        else {
            score = 70;
            details = 'Opiniones sobre mascotas compatibles';
        }
        return {
            factor: 'Mascotas',
            weight,
            score,
            contribution: weight * score,
            details,
        };
    }
    calculatePersonalityCompatibility(s1, s2) {
        const weight = this.weights.personality;
        let score = 0;
        let details = '';
        const traits1 = s1.personalityTraits || [];
        const traits2 = s2.personalityTraits || [];
        if (traits1.length === 0 || traits2.length === 0) {
            score = 50;
            details = 'Intereses no especificados';
        }
        else {
            const commonTraits = traits1.filter((trait) => traits2.includes(trait));
            const totalUniqueTraits = new Set([...traits1, ...traits2]).size;
            if (totalUniqueTraits > 0) {
                score = Math.round((commonTraits.length / totalUniqueTraits) * 100);
            }
            else {
                score = 50;
            }
            if (score >= 70) {
                details = `Compartís ${commonTraits.length} intereses: ${commonTraits.join(', ')}`;
            }
            else if (score >= 40) {
                details = `Tenéis algunos intereses en común`;
            }
            else {
                details = 'Pocos intereses compartidos';
            }
        }
        return {
            factor: 'Personalidad',
            weight,
            score,
            contribution: weight * score,
            details,
        };
    }
    calculateGuestsCompatibility(s1, s2) {
        const weight = this.weights.guests;
        let score = 0;
        let details = '';
        const freq1 = s1.guestsFrequency || 'a_veces';
        const freq2 = s2.guestsFrequency || 'a_veces';
        const frequencyOrder = ['nunca', 'a_veces', 'frecuentemente'];
        const diff = Math.abs(frequencyOrder.indexOf(freq1) - frequencyOrder.indexOf(freq2));
        if (diff === 0) {
            score = 100;
            details = 'Misma frecuencia de visitas';
        }
        else if (diff === 1) {
            score = 75;
            details = 'Frecuencia de visitas compatible';
        }
        else {
            score = 40;
            details = 'Diferencia en frecuencia de visitas';
        }
        return {
            factor: 'Visitas',
            weight,
            score,
            contribution: weight * score,
            details,
        };
    }
    calculateCookingCompatibility(s1, s2) {
        const weight = this.weights.cooking;
        let score = 0;
        let details = '';
        const freq1 = s1.cookingFrequency || 'ocasionalmente';
        const freq2 = s2.cookingFrequency || 'ocasionalmente';
        if (freq1 === freq2) {
            score = 100;
            details = 'Misma frecuencia de cocina';
        }
        else if ((freq1 === 'todos_los_dias' && freq2 !== 'nunca') ||
            (freq2 === 'todos_los_dias' && freq1 !== 'nunca')) {
            score = 80;
            details = 'Compatible en hábitos de cocina';
        }
        else {
            score = 60;
            details = 'Diferentes hábitos de cocina';
        }
        return {
            factor: 'Cocina',
            weight,
            score,
            contribution: weight * score,
            details,
        };
    }
    calculateMusicCompatibility(s1, s2) {
        const weight = this.weights.music;
        let score = 0;
        let details = '';
        const vol1 = s1.musicVolume || 'a_veces';
        const vol2 = s2.musicVolume || 'a_veces';
        const volumeOrder = ['nunca', 'a_veces', 'mucho'];
        const diff = Math.abs(volumeOrder.indexOf(vol1) - volumeOrder.indexOf(vol2));
        if (diff === 0) {
            score = 100;
            details = 'Mismo nivel de tolerancia al ruido';
        }
        else if (diff === 1) {
            score = 70;
            details = 'Tolerancia al ruido compatible';
        }
        else {
            score = 30;
            details = 'Diferencia significativa en tolerancia al ruido';
        }
        return {
            factor: 'Música/Ruido',
            weight,
            score,
            contribution: weight * score,
            details,
        };
    }
    calculateWorkFromHomeCompatibility(s1, s2) {
        const weight = this.weights.workFromHome;
        let score = 0;
        let details = '';
        const wfh1 = s1.workFromHome || false;
        const wfh2 = s2.workFromHome || false;
        if (wfh1 === wfh2) {
            score = 100;
            details = wfh1 ? 'Ambos teletrabajáis' : 'Ninguno teletrabaja';
        }
        else {
            score = 70;
            details = 'Uno teletrabaja y el otro no';
        }
        return {
            factor: 'Teletrabajo',
            weight,
            score,
            contribution: weight * score,
            details,
        };
    }
    generateExplanation(factors, totalScore) {
        const highScoreFactors = factors.filter((f) => f.score >= 70).map((f) => f.details);
        const lowScoreFactors = factors.filter((f) => f.score < 50).map((f) => f.details);
        let explanation = '';
        if (totalScore >= 85) {
            explanation = `¡Excelente compatibilidad! ${highScoreFactors.slice(0, 2).join('. ')}. `;
        }
        else if (totalScore >= 70) {
            explanation = `Muy buena compatibilidad. ${highScoreFactors.slice(0, 2).join('. ')}. `;
        }
        else if (totalScore >= 50) {
            explanation = `Compatibilidad moderada. ${highScoreFactors.slice(0, 1).join('. ')}. `;
        }
        else {
            explanation = `Baja compatibilidad. `;
        }
        if (lowScoreFactors.length > 0) {
            explanation += `Podríais tener diferencias en: ${lowScoreFactors.slice(0, 2).join(', ')}.`;
        }
        return explanation;
    }
}
exports.CompatibilityCalculator = CompatibilityCalculator;
//# sourceMappingURL=compatibility-calculator.js.map
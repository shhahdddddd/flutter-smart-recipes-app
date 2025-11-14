const { openai } = require('../../config/ai.config');
const logger = require('../../utils/logger');

class AIService {
  constructor() {
    this.openai = openai;
  }

  async generateRecipes(ingredients, preferences = {}) {
    const prompt = this.buildRecipePrompt(ingredients, preferences);
    
    try {
      logger.info(`Generating recipes for ingredients: ${ingredients.join(', ')}`);
      
      const completion = await this.openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "Tu es un chef cuisinier expert. Crée des recettes détaillées, équilibrées et faciles à suivre. Réponds uniquement avec du JSON valide."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 2000
      });

      const content = completion.choices[0].message.content;
      const recipes = this.parseAIResponse(content);
      
      logger.info(`Successfully generated ${recipes.recipes?.length || 0} recipes`);
      return recipes;
    } catch (error) {
      logger.error('OpenAI API error:', error);
      throw new Error('Erreur lors de la génération des recettes');
    }
  }

  async generateMenu(ingredients, duration = 'day', preferences = {}) {
    const prompt = this.buildMenuPrompt(ingredients, duration, preferences);

    try {
      logger.info(`Generating ${duration} menu with ingredients: ${ingredients.join(', ')}`);
      
      const completion = await this.openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "Tu es un nutritionniste et chef cuisinier. Crée des menus équilibrés et variés. Réponds uniquement avec du JSON valide."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 2000
      });

      const content = completion.choices[0].message.content;
      const menu = this.parseAIResponse(content);
      
      logger.info(`Successfully generated ${duration} menu`);
      return menu;
    } catch (error) {
      logger.error('OpenAI API error:', error);
      throw new Error('Erreur lors de la génération du menu');
    }
  }

  buildRecipePrompt(ingredients, preferences) {
    return `Crée 3 recettes utilisant principalement ces ingrédients: ${ingredients.join(', ')}.
    
Préférences alimentaires: ${preferences.diet || 'Aucune'}
Allergies: ${preferences.allergies ? preferences.allergies.join(', ') : 'Aucune'}
Temps de préparation maximum: ${preferences.maxCookingTime || '60'} minutes
Difficulté: ${preferences.difficulty || 'Tous niveaux'}
    
Format de réponse JSON strict:
{
  "recipes": [
    {
      "title": "Nom de la recette",
      "description": "Description courte",
      "ingredients": [
        {"name": "ingrédient", "quantity": "quantité", "note": "note optionnelle"}
      ],
      "instructions": [
        {"step": 1, "description": "description étape 1"},
        {"step": 2, "description": "description étape 2"}
      ],
      "cookingTime": 30,
      "difficulty": "easy",
      "category": "dinner",
      "calories": 450,
      "tags": ["tag1", "tag2"]
    }
  ]
}`;
  }

  buildMenuPrompt(ingredients, duration, preferences) {
    return `Crée un menu ${duration === 'week' ? 'hebdomadaire' : 'quotidien'} avec:
Ingrédients disponibles: ${ingredients.join(', ')}
Préférences: ${JSON.stringify(preferences)}

Structure de réponse en JSON:
{
  "menu": {
    "title": "Titre du menu",
    "description": "Description du menu",
    "duration": ${duration === 'week' ? 7 : 1},
    "meals": [
      {
        "day": 1,
        "mealType": "breakfast",
        "recipe": {
          "title": "Titre recette",
          "ingredients": [{"name": "ingrédient", "quantity": "quantité"}],
          "instructions": [{"step": 1, "description": "..."}],
          "cookingTime": 10,
          "difficulty": "easy"
        }
      }
    ]
  },
  "shoppingList": [
    {"ingredient": "nom", "quantity": "quantité"}
  ]
}`;
  }

  parseAIResponse(response) {
    try {
      const jsonMatch = response.match(/```json\n([\s\S]*?)\n```/) || 
                       response.match(/{[\s\S]*}/);
      
      if (jsonMatch) {
        const jsonString = jsonMatch[1] || jsonMatch[0];
        return JSON.parse(jsonString);
      }
      
      throw new Error('Aucun JSON trouvé dans la réponse');
    } catch (error) {
      logger.error('AI response parsing error:', error);
      logger.debug('Raw AI response:', response);
      throw new Error('Erreur lors de l\'analyse de la réponse de l\'IA');
    }
  }
}

module.exports = new AIService();
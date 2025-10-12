<?php

namespace app\models;

use Yii;
use yii\behaviors\TimestampBehavior;
use yii\db\Expression;

/**
 * This is the model class for table "grid_view_columns".
 *
 * @property int $id
 * @property string $grid_id A unique identifier for the grid view (e.g., Controller-Action)
 * @property string $attribute The attribute name of the column.
 * @property string $label The header label of the column.
 * @property int|null $created_at
 * @property int|null $updated_at
 *
 * @property UserGridViewPreference[] $userGridViewPreferences
 */
class GridViewColumn extends \yii\db\ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'grid_view_columns';
    }

    /**
     * {@inheritdoc}
     */
    public function behaviors()
    {
        return [
            [
                'class' => TimestampBehavior::class,
                'value' => new Expression('NOW()'),
            ],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['grid_id', 'attribute', 'label'], 'required'],
            [['grid_id', 'attribute', 'label'], 'string', 'max' => 255],
            [['grid_id', 'attribute'], 'unique', 'targetAttribute' => ['grid_id', 'attribute']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'grid_id' => 'Grid ID',
            'attribute' => 'Attribute',
            'label' => 'Label',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }

    /**
     * Gets query for [[UserGridViewPreferences]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getUserGridViewPreferences()
    {
        return $this->hasMany(UserGridViewPreference::class, ['grid_view_column_id' => 'id']);
    }
} 
<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "vehicle_type".
 *
 * @property int $id
 * @property string|null $vehicle_type
 * @property string|null $created
 * @property string|null $updated
 * @property int|null $userId
 */
class VehicleType extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'vehicle_type';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['vehicle_type', 'created', 'updated', 'userId'], 'default', 'value' => null],
            [['created', 'updated'], 'safe'],
            [['userId'], 'integer'],
            [['vehicle_type'], 'string', 'max' => 50],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'vehicle_type' => 'Vehicle Type',
            'created' => 'Created',
            'updated' => 'Updated',
            'userId' => 'User ID',
        ];
    }

}

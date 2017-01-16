# encoding: UTF-8

class EventoMotivonodenuncia < ActiveRecord::Base
	belongs_to :evento, class_name: '::Evento',
    foreign_key: 'evento_id', validate: true
	belongs_to :motivonodenuncia, class_name: '::Motivonodenuncia',
    foreign_key: 'motivonodenuncia_id', validate: true
end
